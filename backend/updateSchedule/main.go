package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
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

type Schedule struct {
	Updated       string          `json:"updated"`
	Events        json.RawMessage `json:"events"`
	NextPageToken string
	CurrentPage   int
}

type Event struct {
	StartTime string          `json:"startTime"`
	State     string          `json:"state"`
	Type      string          `json:"type"`
	Match     json.RawMessage `json:"match"`
}

type Match struct {
	ID        string      `json:"-"`
	StartTime string      `json:":time"`
	State     string      `json:":state"`
	Teams     [2]string   `json:":teams"`
	Strategy  Strategy    `json:":strat"`
	Games     interface{} `json:"-"`
}

type Strategy struct {
	Type  string `json:"type"`
	Count int    `json:"count"`
}

func isEqual(a, b Match) bool {
	if &a == &b {
		return true
	}
	if a.ID != b.ID ||
		a.StartTime != b.StartTime ||
		a.State != b.State ||
		a.Teams != b.Teams ||
		a.Strategy != b.Strategy {
		return false
	}
	return true
}

var (
	APIKey = os.Getenv("APIKEY")

	// Since Lambda is kept warm, it will save global variables.
	// prevSchedule and prevMatches are essentially caches
	prevSchedule   = make(map[int][]byte)
	prevMatches    map[string]Match
	prevMatchesAge time.Time

	db = common.ConnectToDynamoDb()
)

func handler() {
	log.SetFlags(log.Lshortfile)
	if prevMatchesAge.IsZero() || time.Now().Sub(prevMatchesAge).Minutes() >= 60 {
		println("Making new prevMatches map")
		prevMatches = make(map[string]Match)
		prevMatchesAge = time.Now()
	}

	pageNumber := 1
	nextPageToken := ""
	for pageNumber != -1 {
		responseBytes, err := pullSchedule(nextPageToken)
		if err != nil {
			log.Printf("Error pulling schedule: %s\n", err)
			return
		}

		schedule, scheduleJson, err := createSchedule(responseBytes, pageNumber)
		if err != nil {
			log.Printf("Error creating schedule: %s\n", err)
			return
		}

		compareAndUpdateDynamoDb(schedule, scheduleJson)

		nextPageToken = schedule.NextPageToken
		if len(nextPageToken) == 0 {
			break
		}
		pageNumber++
	}
}

func pullSchedule(pageToken string) ([]byte, error) {
	getScheduleAddress := "https://esports-api.lolesports.com/persisted/gw/getSchedule?hl=en-US"
	if pageToken != "" {
		getScheduleAddress += fmt.Sprintf("&pageToken=%s", pageToken)
	}

	req, err := http.NewRequest("GET", getScheduleAddress, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Add("x-api-key", APIKey)
	client := &http.Client{
		Timeout: 10 * time.Second,
	}
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

func createSchedule(scheduleBytes []byte, pageNumber int) (*Schedule, string, error) {
	scheduleResult := gjson.GetBytes(scheduleBytes, "data.schedule")

	var rawSchedule []byte
	if scheduleResult.Index > 0 {
		rawSchedule = scheduleBytes[scheduleResult.Index : scheduleResult.Index+len(scheduleResult.Raw)]
	} else {
		rawSchedule = []byte(scheduleResult.Raw)
	}

	var schedule Schedule
	err := json.Unmarshal(rawSchedule, &schedule)
	if err != nil {
		return nil, "", err
	}

	nextPageTokenResult := gjson.GetBytes(scheduleBytes, "data.schedule.pages.newer")
	schedule.NextPageToken = nextPageTokenResult.String()
	schedule.CurrentPage = pageNumber

	return &schedule, scheduleResult.String(), nil
}

func getStrategy(rawMatch []byte) (Strategy, error) {
	strategyResult := gjson.GetBytes(rawMatch, "strategy")

	var rawStrategy []byte
	if strategyResult.Index > 0 {
		rawStrategy = rawMatch[strategyResult.Index : strategyResult.Index+len(strategyResult.Raw)]
	} else {
		rawStrategy = []byte(strategyResult.Raw)
	}

	var strategy Strategy
	err := json.Unmarshal(rawStrategy, &strategy)
	if err != nil {
		return strategy, err
	}
	return strategy, nil
}

func updateDB(wg *sync.WaitGroup, input *dynamodb.UpdateItemInput) {
	defer wg.Done()

	_, err := db.UpdateItem(input)
	common.CheckDbResponseError(err)
}

func updateMatchesInDynamoDb(wg *sync.WaitGroup, matches []Match) {
	encoder := dynamodbattribute.NewEncoder(func(e *dynamodbattribute.Encoder) {
		e.EnableEmptyCollections = true
	})

	for _, match := range matches {

		matchJson, err := dynamodbattribute.MarshalMap(match)
		if err != nil {
			log.Println("Error marshalling match", err)
			return
		}

		// The only way I found that was able to insert an empty map was to use an encoder with EnableEmptyCollections on
		gameAlarmsMap, err := encoder.Encode(match.Games)
		matchJson[":gameAlarms"] = gameAlarmsMap

		input := &dynamodb.UpdateItemInput{
			TableName: aws.String("Matches"),
			Key: map[string]*dynamodb.AttributeValue{
				"id": {
					N: aws.String(match.ID),
				},
			},
			ExpressionAttributeNames: map[string]*string{
				"#STATE": aws.String("state"),
			},
			ExpressionAttributeValues: matchJson,
			UpdateExpression:          aws.String("SET startTime = :time, #STATE = :state, strategy = :strat, teams = :teams, games = if_not_exists(games, :gameAlarms)"),
			//UpdateExpression: aws.String("SET startTime = :time, #STATE = :state, strategy = :strat, teams = :teams, games = :gameAlarms"),
		}

		wg.Add(1)
		go updateDB(wg, input)
	}
}

func updateScheduleInDynamoDb(wg *sync.WaitGroup, schedule string, page int) {
	input := &dynamodb.UpdateItemInput{
		TableName: aws.String("Schedule"),
		Key: map[string]*dynamodb.AttributeValue{
			"page": {
				N: aws.String(strconv.Itoa(page)),
			},
		},
		ExpressionAttributeValues: map[string]*dynamodb.AttributeValue{
			":s": {
				S: aws.String(schedule),
			},
		},
		UpdateExpression: aws.String("SET schedule = :s"),
	}

	wg.Add(1)
	go updateDB(wg, input)
}

func compareAndUpdateDynamoDb(schedule *Schedule, scheduleJSON string) {
	if bytes.Equal(prevSchedule[schedule.CurrentPage], schedule.Events) {
		fmt.Printf("Page %d contains the same schedule as last update\n", schedule.CurrentPage)
		return
	}
	prevSchedule[schedule.CurrentPage] = schedule.Events

	var matchEvents []Event
	err := json.Unmarshal(schedule.Events, &matchEvents)
	if err != nil {
		log.Printf("Error unmarshalling events: %s\n", err)
		return
	}

	updateWG := sync.WaitGroup{}
	updateScheduleInDynamoDb(&updateWG, scheduleJSON, schedule.CurrentPage)

	var matchesToUpdate []Match
	var matches = make(map[string]Match)
	for _, matchEvent := range matchEvents {
		if matchEvent.Type != "match" {
			continue
		}

		matchID := gjson.GetBytes(matchEvent.Match, "id").String()
		teamsResult := gjson.GetBytes(matchEvent.Match, "teams.#.name").Array()
		teams := [2]string{teamsResult[0].String(), teamsResult[1].String()}

		strategy, err := getStrategy(matchEvent.Match)
		if err != nil {
			log.Println("Error getting the strategy of a match.")
			continue
		}

		gamesMap := make(map[int]interface{})
		for i := 1; i <= strategy.Count; i++ {
			gamesMap[i] = map[string]interface{}{}
		}

		match := Match{
			ID:        matchID,
			StartTime: matchEvent.StartTime,
			State:     matchEvent.State,
			Teams:     teams,
			Strategy:  strategy,
			Games:     gamesMap,
		}
		matches[matchID] = match

		prevMatchVersion, ok := prevMatches[matchID]
		if (ok && !isEqual(prevMatchVersion, match)) || !ok {
			matchesToUpdate = append(matchesToUpdate, match)
			prevMatches[matchID] = match
		}
	}

	if len(matchesToUpdate) == 0 {
		fmt.Printf("Schedule page %d contains the same matches as last update\n", schedule.CurrentPage)
	} else {
		fmt.Printf("Schedule page %d contains different matches from last update\n", schedule.CurrentPage)
		updateMatchesInDynamoDb(&updateWG, matchesToUpdate)
	}

	updateWG.Wait()
}

func main() {
	lambda.Start(handler)
}
