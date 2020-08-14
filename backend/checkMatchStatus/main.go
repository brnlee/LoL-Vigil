package main

import (
	"encoding/json"
	"fmt"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/sns"
	"github.com/brnlee/LoL-Vigil/common"
	"github.com/tidwall/gjson"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strconv"
	"sync"
	"time"
)

const (
	GetLive           = "https://esports-api.lolesports.com/persisted/gw/getLive?hl=en-US"
	GetEventDetails   = "https://esports-api.lolesports.com/persisted/gw/getEventDetails?hl=en-US"
	GetLiveGameFrames = "https://feed.lolesports.com/livestats/v1/window/"
)

var (
	APIKey = os.Getenv("APIKEY")

	client = &http.Client{
		Timeout: 10 * time.Second,
	}
	db = common.ConnectToDynamoDb()
)

type Game struct {
	Number int    `json:"number"`
	ID     string `json:"id"`
	State  string `json:"state"`
}

func handler() {
	log.SetFlags(log.Lshortfile)

	liveMatches, err := getLive()
	if err != nil {
		log.Printf("Error getting live matches: %s\n", err)
		return
	}

	liveMatchIDs := gjson.GetBytes(liveMatches, "data.schedule.events.#.match.id")
	var wg sync.WaitGroup
	for _, matchID := range liveMatchIDs.Array() {
		log.Println(matchID)
		wg.Add(1)
		go checkLiveMatchStatus(matchID.String(), &wg)
	}

	wg.Wait()
}

func checkLiveMatchStatus(matchID string, wg *sync.WaitGroup) {
	defer wg.Done()
	games, err := getGames(matchID)
	if err != nil {
		log.Printf("Error getting games for match %s: %s\n", matchID, err)
		return
	}

	sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))
	svc := sns.New(sess)

	for _, game := range games {
		if game.State == "completed" {
			continue
		} else if game.State == "unstarted" {
			break
		} else if game.State == "inProgress" {
			gameDetails, err := getGameStatus(game)
			//log.Printf("%+v\n", gameDetails)
			if err != nil {
				log.Printf("Error getting game status for %s-%s: %s\n", matchID, game.ID, err)
				return
			}

			if gameDetails.Frames[len(gameDetails.Frames)-1].GameState == common.InGame {
				updateTimestampsInDB(gameDetails)

				gameDetailsJson, err := json.Marshal(gameDetails)
				if err != nil {
					log.Printf("Error marshalling game details: %s\n", err)
					return
				}

				log.Println(gameDetailsJson)

				result, err := svc.Publish(&sns.PublishInput{
					Message:  aws.String(string(gameDetailsJson)),
					TopicArn: aws.String(os.Getenv("SendNotificationsSNSTopicARN")),
				})
				if err != nil {
					log.Printf("Error publishing to SNS: %s\n", err)
					return
				}

				log.Println(*result.MessageId)
			}
		}
	}
}

func getLive() ([]byte, error) {
	req, err := http.NewRequest("GET", GetLive, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Add("x-api-key", APIKey)
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	} else if resp.StatusCode != 200 {
		return nil, fmt.Errorf("Non 200 Response found\n")
	}

	responseBytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	return responseBytes, nil
}

func getGames(matchID string) ([]Game, error) {
	eventDetailsAddress := GetEventDetails + fmt.Sprintf("&id=%s", matchID)
	req, err := http.NewRequest("GET", eventDetailsAddress, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Add("x-api-key", APIKey)
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}

	responseBytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	} else if resp.StatusCode != 200 {
		return nil, fmt.Errorf("Non 200 Response found while getting live game IDs: %s\n", responseBytes)
	}

	numGames := gjson.GetBytes(responseBytes, "data.event.match.strategy.count").Int()

	games := make([]Game, numGames)
	gamesArrayResult := gjson.GetBytes(responseBytes, "data.event.match.games")
	for i, gameResult := range gamesArrayResult.Array() {
		var rawGame []byte
		if gameResult.Index > 0 {
			rawGame = responseBytes[gameResult.Index : gameResult.Index+len(gameResult.Raw)]
		} else {
			rawGame = []byte(gameResult.Raw)
		}

		var game Game
		err := json.Unmarshal(rawGame, &game)
		if err != nil {
			return nil, err
		}
		games[i] = game
	}

	return games, nil
}

func getGameStatus(game Game) (common.GameDetails, error) {
	currentTime := time.Now().Add(-20 * time.Second)
	startingTime := currentTime.Add(time.Duration(-(currentTime.Second() % 10)) * time.Second)
	windowAddress := GetLiveGameFrames + fmt.Sprintf("%s?startingTime=%s", game.ID, startingTime.Format(time.RFC3339))

	req, err := http.NewRequest("GET", windowAddress, nil)
	if err != nil {
		return common.GameDetails{}, err
	}

	req.Header.Add("x-api-key", APIKey)
	resp, err := client.Do(req)
	if err != nil {
		return common.GameDetails{}, err
	}

	responseBytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return common.GameDetails{}, err
	} else if resp.StatusCode != 200 {
		return common.GameDetails{}, fmt.Errorf("Non 200 Response found while getting game windows. Game may not have started yet: %s\n", responseBytes)
	}

	gameDetails, err := common.UnmarshalGameDetails(responseBytes)
	if err != nil {
		return common.GameDetails{}, err
	}

	gameDetails.GameNumber = strconv.Itoa(game.Number)

	return gameDetails, nil
}

func updateTimestampsInDB(gameDetails common.GameDetails) {
	attributeValues := make(map[string]*dynamodb.AttributeValue)
	lastFrame := gameDetails.Frames[len(gameDetails.Frames)-1]

	gameBeginsUpdatePath := "gameTimestamps.#GameNumber.gameBegins"
	attributeValues[":gameBeginsTime"] = &dynamodb.AttributeValue{S: aws.String(lastFrame.Rfc460Timestamp)}

	updateExpression := fmt.Sprintf("SET %s = if_not_exists(%s, :gameBeginsTime)", gameBeginsUpdatePath, gameBeginsUpdatePath)

	if lastFrame.BlueTeam.TotalKills > 0 || lastFrame.RedTeam.TotalKills > 0 {
		firstBloodUpdatePath := "gameTimestamps.#GameNumber.firstBlood"
		updateExpression += fmt.Sprintf(", %s = if_not_exists(%s, :firstBloodTime)", firstBloodUpdatePath, firstBloodUpdatePath)
		attributeValues[":firstBloodTime"] = &dynamodb.AttributeValue{S: aws.String(lastFrame.Rfc460Timestamp)}
	}

	input := &dynamodb.UpdateItemInput{
		TableName: aws.String("Matches"),
		Key: map[string]*dynamodb.AttributeValue{
			"id": {
				N: aws.String(gameDetails.MatchID),
			},
		},
		ExpressionAttributeNames: map[string]*string{
			"#GameNumber": aws.String(gameDetails.GameNumber),
		},
		ExpressionAttributeValues: attributeValues,
		UpdateExpression:          aws.String(updateExpression),
	}
	_, err := db.UpdateItem(input)
	common.CheckDbResponseError(err)
}

func main() {
	lambda.Start(handler)
}
