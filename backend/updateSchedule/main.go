package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"github.com/tidwall/gjson"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"sync"
)

type Schedule struct {
	Updated string          `json:"updated"`
	Events  json.RawMessage `json:"events"`
}

type Event struct {
	StartTime string          `json:"startTime"`
	State     string          `json:"state"`
	Match     json.RawMessage `json:"match"`
}

type Match struct {
	ID        string   `json:":matchID"`
	StartTime string   `json:":time"`
	State     string   `json:":state"`
	Strategy  Strategy `json:":strat"`
}

type Strategy struct {
	Type  string `json:"type"`
	Count int    `json:"count"`
}

var (
	DefaultHTTPGetAddress = "https://esports-api.lolesports.com/persisted/gw/getSchedule?hl=en-US"
	APIKey                = os.Getenv("APIKEY")

	// Since Lambda is kept warm, it will save global variables.
	// prevMatches is essentially a cache
	prevSchedule []byte
	prevMatches  map[string]Match

	db = connectToDynamoDb()
)

func handler() {
	log.SetFlags(log.Lshortfile)
	responseBytes, err := pullSchedule()
	if err != nil {
		log.Printf("Error pulling schedule: %s\n", err)
		return
	}

	schedule, scheduleJson, err := createSchedule(responseBytes)
	if err != nil {
		log.Printf("Error creating schedule: %s\n", err)
		return
	}

	if bytes.Equal(prevSchedule, schedule.Events) {
		fmt.Printf("Same schedule as last update\n")
		return
	}
	prevSchedule = schedule.Events

	var matchEvents []Event
	err = json.Unmarshal(schedule.Events, &matchEvents)
	if err != nil {
		log.Printf("Error unmarshalling events: %s\n", err)
		return
	}

	var wg sync.WaitGroup

	updateScheduleInDynamoDb(&wg, scheduleJson)

	var matchesToUpdate []Match
	var matches = make(map[string]Match)
	for _, matchEvent := range matchEvents {
		matchID := gjson.GetBytes(matchEvent.Match, "id").String()

		strategy, err := getStrategy(matchEvent.Match)
		if err != nil {
			println("Error getting the strategy of a match.")
			continue
		}

		match := Match{
			ID:        matchID,
			StartTime: matchEvent.StartTime,
			State:     matchEvent.State,
			Strategy:  strategy,
		}
		matches[matchID] = match

		prevMatchVersion, ok := prevMatches[matchID]
		if (ok && prevMatchVersion != match) || !ok {
			matchesToUpdate = append(matchesToUpdate, match)
		}
	}

	prevMatches = matches

	if len(matchesToUpdate) == 0 {
		fmt.Printf("Same matches as last update\n")
	} else {
		fmt.Printf("Different matches from last update\n")
		updateMatchesInDynamoDb(&wg, matchesToUpdate)
	}

	wg.Wait()
}

func pullSchedule() ([]byte, error) {
	req, err := http.NewRequest("GET", DefaultHTTPGetAddress, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Add("x-api-key", APIKey)
	client := &http.Client{}
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

func createSchedule(scheduleBytes []byte) (*Schedule, string, error) {
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

func connectToDynamoDb() *dynamodb.DynamoDB {
	isSAMLocal := os.Getenv("AWS_SAM_LOCAL")

	var config *aws.Config
	if isSAMLocal == "true" {
		config = &aws.Config{
			Endpoint: aws.String("http://dynamodb:8000"),
		}
	}

	sess, err := session.NewSession(config)
	if err != nil {
		println(err.Error())
	}

	return dynamodb.New(sess)
}

func updateDB(wg *sync.WaitGroup, input *dynamodb.UpdateItemInput) {
	defer wg.Done()

	_, err := db.UpdateItem(input)
	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case dynamodb.ErrCodeConditionalCheckFailedException:
				fmt.Println(dynamodb.ErrCodeConditionalCheckFailedException, aerr.Error())
			case dynamodb.ErrCodeProvisionedThroughputExceededException:
				fmt.Println(dynamodb.ErrCodeProvisionedThroughputExceededException, aerr.Error())
			case dynamodb.ErrCodeResourceNotFoundException:
				fmt.Println(dynamodb.ErrCodeResourceNotFoundException, aerr.Error())
			case dynamodb.ErrCodeItemCollectionSizeLimitExceededException:
				fmt.Println(dynamodb.ErrCodeItemCollectionSizeLimitExceededException, aerr.Error())
			case dynamodb.ErrCodeTransactionConflictException:
				fmt.Println(dynamodb.ErrCodeTransactionConflictException, aerr.Error())
			case dynamodb.ErrCodeRequestLimitExceeded:
				fmt.Println(dynamodb.ErrCodeRequestLimitExceeded, aerr.Error())
			case dynamodb.ErrCodeInternalServerError:
				fmt.Println(dynamodb.ErrCodeInternalServerError, aerr.Error())
			default:
				fmt.Println(aerr.Error())
			}
		} else {
			fmt.Println(err.Error())
		}
	}
}

func updateMatchesInDynamoDb(wg *sync.WaitGroup, matches []Match) {
	for _, match := range matches {
		fmt.Printf("%+v\n", match)
		matchJson, err := dynamodbattribute.MarshalMap(match)
		if err != nil {
			println("Error marshalling match", err)
			return
		}

		input := &dynamodb.UpdateItemInput{
			TableName: aws.String("Matches"),
			Key: map[string]*dynamodb.AttributeValue{
				"id": {
					N: aws.String(match.ID),
				},
			},
			ExpressionAttributeValues: matchJson,
			ExpressionAttributeNames: map[string]*string{
				"#STATE": aws.String("state"),
			},
			UpdateExpression: aws.String("SET matchID = :matchID, startTime = :time, #STATE = :state, strategy = :strat"),
		}

		wg.Add(1)
		go updateDB(wg, input)
	}
}

func updateScheduleInDynamoDb(wg *sync.WaitGroup, schedule string) {
	wg.Add(1)

	input := &dynamodb.UpdateItemInput{
		TableName: aws.String("Matches"),
		Key: map[string]*dynamodb.AttributeValue{
			"id": {
				N: aws.String("-1"),
			},
		},
		ExpressionAttributeValues: map[string]*dynamodb.AttributeValue{
			":s": {
				S: aws.String(schedule),
			},
		},
		UpdateExpression: aws.String("SET schedule = :s"),
	}

	go updateDB(wg, input)
}

func main() {
	lambda.Start(handler)
}
