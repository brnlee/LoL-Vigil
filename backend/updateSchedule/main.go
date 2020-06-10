package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/tidwall/gjson"
	"io/ioutil"
	"log"
	"net/http"
	"os"
)

type Schedule struct {
	Updated string          `json:"updated"`
	Events  json.RawMessage `json:"events"`
}

type Event struct {
	StartTime string          `json:"startTime"`
	State     string          `json:"state"`
	Match     json.RawMessage `json:"match"`
	Strategy  Strategy        `json:"strategy"`
}

type Strategy struct {
	Type  string `json:"type"`
	Count int    `json:"count"`
}

type Match struct {
	ID        string `json:"id"`
	StartTime string
	State     string
	Strategy  Strategy
}

var (
	DefaultHTTPGetAddress = "https://esports-api.lolesports.com/persisted/gw/getSchedule?hl=en-US"
	APIKey                = os.Getenv("APIKEY")
	prevSchedule          Schedule
)

func handler(event events.CloudWatchEvent) {
	log.SetFlags(log.Lshortfile)
	req, err := http.NewRequest("GET", DefaultHTTPGetAddress, nil)

	if err != nil {
		log.Printf("error: %s\n", err)
		return
	}

	req.Header.Add("x-api-key", APIKey)
	client := &http.Client{}
	resp, err := client.Do(req)

	if err != nil {
		log.Printf("error: %s\n", err)
		return
	} else if resp.StatusCode != 200 {
		log.Printf("Non 200 Response found\n")
		return
	}

	responseBytes, err := ioutil.ReadAll(resp.Body)

	if err != nil {
		log.Printf("error: %s\n", err)
		return
	}

	scheduleResult := gjson.GetBytes(responseBytes, "data.schedule")
	var rawSchedule []byte
	if scheduleResult.Index > 0 {
		rawSchedule = responseBytes[scheduleResult.Index : scheduleResult.Index+len(scheduleResult.Raw)]
	} else {
		rawSchedule = []byte(scheduleResult.Raw)
	}

	var schedule Schedule
	err = json.Unmarshal(rawSchedule, &schedule)
	if err != nil {
		log.Printf("error: %s\n", err)
		return
	}

	if bytes.Equal(prevSchedule.Events, schedule.Events) {
		fmt.Printf("Same schedule as last update\n")
	} else {
		fmt.Printf("Different schedule from last update: %s != %s\n",
			prevSchedule.Updated, schedule.Updated)
		prevSchedule = schedule
	}

	var matchEvents []Event
	err = json.Unmarshal(schedule.Events, &matchEvents)
	if err != nil {
		log.Printf("error: %s\n", err)
		return
	}

	var matches []Match
	for _, matchEvent := range matchEvents {
		matchID := gjson.GetBytes(matchEvent.Match, "id")
		var match = Match{
			ID:        matchID.String(),
			StartTime: matchEvent.StartTime,
			State:     matchEvent.State,
			Strategy:  matchEvent.Strategy,
		}
		matches = append(matches, match)
	}

}

func main() {
	lambda.Start(handler)
}
