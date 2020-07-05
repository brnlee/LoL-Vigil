package main

import (
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/tidwall/gjson"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"time"
)

type CachedLeagues struct {
	getLeaguesResponse string
	TimeLastUpdated    time.Time
}

var (
	// Since Lambda is kept warm, it will save global variables.
	cache = CachedLeagues{}
)

func handler() (events.APIGatewayProxyResponse, error) {
	log.SetFlags(log.Lshortfile)

	if len(cache.getLeaguesResponse) == 0 || time.Now().Sub(cache.TimeLastUpdated).Minutes() >= 10 {
		println("Refreshing leagues...")
		updateLeagues()
	}

	return events.APIGatewayProxyResponse{
		Body:       cache.getLeaguesResponse,
		StatusCode: http.StatusOK,
		Headers:    map[string]string{"Content-Type": "application/json"},
	}, nil
}

func updateLeagues() {
	getScheduleAddress := "https://esports-api.lolesports.com/persisted/gw/getLeagues?hl=en-US"

	req, err := http.NewRequest("GET", getScheduleAddress, nil)
	if err != nil {
		return
	}

	req.Header.Add("x-api-key", os.Getenv("APIKEY"))
	client := &http.Client{
		Timeout: 10 * time.Second,
	}
	resp, err := client.Do(req)
	if err != nil {
		return
	} else if resp.StatusCode != 200 {
		log.Println("Non 200 Response found while updating leagues.")
		return
	}

	responseBytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return
	}

	leaguesResult := gjson.GetBytes(responseBytes, "data")
	cache.getLeaguesResponse = leaguesResult.String()
	cache.TimeLastUpdated = time.Now()
}

func main() {
	lambda.Start(handler)
}
