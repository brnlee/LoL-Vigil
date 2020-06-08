package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"io/ioutil"
	"net/http"
	"os"
)

type Response struct {
	Data Data `json:"data"`
}

type Data struct {
	Schedule Schedule `json:"schedule"`
}

type Schedule struct {
	Updated string          `json:"updated"`
	Events  json.RawMessage `json:"events"`
}

type Event struct {
	StartTime string `json:"startTime"`
	State     string `json:"state"`
}

var (
	DefaultHTTPGetAddress = "https://esports-api.lolesports.com/persisted/gw/getSchedule?hl=en-US"
	APIKey                = os.Getenv("APIKEY")

	ErrNon200Response = "Non 200 Response found"

	prevSchedule Schedule
)

func handler(event events.CloudWatchEvent) {
	req, err := http.NewRequest("GET", DefaultHTTPGetAddress, nil)

	if err != nil {
		fmt.Printf("error: %s\n", err)
		return
	}

	req.Header.Add("x-api-key", APIKey)
	client := &http.Client{}
	resp, err := client.Do(req)

	if err != nil {
		fmt.Printf("error: %s\n", err)
		return
	}

	if resp.StatusCode != 200 {
		println(ErrNon200Response)
	}

	scheduleBlob, err := ioutil.ReadAll(resp.Body)

	if err != nil {
		fmt.Printf("error: %s\n", err)
		return
	}

	var response Response

	err = json.Unmarshal(scheduleBlob, &response)
	if err != nil {
		fmt.Printf("error: %s\n", err)
		return
	}

	if bytes.Equal(prevSchedule.Events, response.Data.Schedule.Events) {
		fmt.Printf("Same schedule as last update\n")
	} else {
		fmt.Printf("Different schedule from last update: %s != %s\n",
			prevSchedule.Updated, response.Data.Schedule.Updated)
		prevSchedule = response.Data.Schedule
	}
}

func main() {
	lambda.Start(handler)
}
