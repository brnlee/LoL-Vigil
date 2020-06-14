package main

import (
	"errors"
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"github.com/brnlee/LoL-Vigil/utils"
	"time"
)

type Cache struct {
	Schedule        string
	TimeLastUpdated time.Time
}

var (
	ErrNoSchedule = errors.New("failed to get schedule")

	db = utils.ConnectToDynamoDb()

	cache Cache
)

func handler(request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	cacheAge := time.Now().Sub(cache.TimeLastUpdated)
	if (cache != Cache{}) && cacheAge.Seconds() < 60 {
		fmt.Printf("Retrieved schedule from cache. CacheAge is %f\n", cacheAge.Seconds())
		return events.APIGatewayProxyResponse{
			Body:       cache.Schedule,
			StatusCode: 200,
		}, nil
	}

	schedule, err := getScheduleFromDb()
	if err != nil {
		return events.APIGatewayProxyResponse{}, ErrNoSchedule
	}

	cache = Cache{
		Schedule:        schedule,
		TimeLastUpdated: time.Now(),
	}

	return events.APIGatewayProxyResponse{
		Body:       schedule,
		StatusCode: 200,
	}, nil
}

func getScheduleFromDb() (string, error) {
	input := &dynamodb.GetItemInput{
		TableName: aws.String("Matches"),
		Key: map[string]*dynamodb.AttributeValue{
			"id": {
				N: aws.String("-1"),
			},
		},
	}
	result, err := db.GetItem(input)
	if err != nil {
		utils.CheckDbResponseError(err)
		return "", err
	}

	type Item struct {
		Schedule string `json:"schedule"`
	}

	item := Item{}
	err = dynamodbattribute.UnmarshalMap(result.Item, &item)
	if err != nil {
		println("Error unmarshalling schedule result")
		return "", err
	}

	return item.Schedule, nil
}

func main() {
	lambda.Start(handler)
}
