package main

import (
	"encoding/json"
	"fmt"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/brnlee/LoL-Vigil/common"
	"github.com/tidwall/gjson"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"time"
)

var (
	APIKey                 = os.Getenv("APIKEY")
	getLiveAddress         = "https://esports-api.lolesports.com/persisted/gw/getLive?hl=en-US"
	getEventDetailsAddress = "https://esports-api.lolesports.com/persisted/gw/getEventDetails?hl=en-US"
	getWindowAddress       = "https://feed.lolesports.com/livestats/v1/window/"
	client                 = &http.Client{
		Timeout: 10 * time.Second,
	}
)

type Game struct {
	Number int64  `json:"number"`
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
	for _, matchID := range liveMatchIDs.Array() {
		go checkLiveMatchStatus(matchID.String())
	}
}

func checkLiveMatchStatus(matchID string) {
	games, err := getGames(matchID)
	if err != nil {
		log.Printf("Error getting games for match %s: %s\n", matchID, err)
	}

	for _, game := range games {
		if game.State == "completed" {
			continue
		} else if game.State == "unstarted" {
			break
		} else if game.State == "in_game" {
			gameDetails, err := getGameStatus(game)
			if err != nil {
				log.Printf("Error getting games details match %s: %s\n", matchID, err)
			}

			if gameDetails.Frames[len(gameDetails.Frames)-1].GameState == common.InGame {
				// todo: make another lambda func to send notifications
				log.Println("Sending notifications...")
			}
		}
	}
}

func getLive() ([]byte, error) {
	req, err := http.NewRequest("GET", getLiveAddress, nil)
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
	getEventDetailsAddress += fmt.Sprintf("&id=%s", matchID)
	req, err := http.NewRequest("GET", getEventDetailsAddress, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Add("x-api-key", APIKey)
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	} else if resp.StatusCode != 200 {
		return nil, fmt.Errorf("Non 200 Response found while getting live game IDs\n")
	}

	responseBytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
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
	currentTime := time.Now()
	startingTime := currentTime.Add(time.Duration(-(currentTime.Second() % 10)) * time.Second)
	getEventDetailsAddress += fmt.Sprintf("&id=%s?currentTime=%s", game.ID, startingTime.Format(time.RFC3339))
	req, err := http.NewRequest("GET", getWindowAddress, nil)
	if err != nil {
		return common.GameDetails{}, err
	}

	resp, err := client.Do(req)
	if err != nil {
		return common.GameDetails{}, err
	} else if resp.StatusCode != 200 {
		return common.GameDetails{}, fmt.Errorf("Non 200 Response found while getting game windows\n")
	}

	responseBytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return common.GameDetails{}, err
	}

	gameDetails, err := common.UnmarshalGameDetails(responseBytes)
	if err != nil {
		return common.GameDetails{}, err
	}

	return gameDetails, nil
}

func main() {
	lambda.Start(handler)
}
