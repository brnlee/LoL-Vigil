package main

import (
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"github.com/brnlee/LoL-Vigil/common"
	"net/http"
	"time"
)

type CachedSchedulePage struct {
	Schedule        string
	TimeLastUpdated time.Time
}

var (
	db = common.ConnectToDynamoDb()

	cache = make(map[string]CachedSchedulePage)
)

func handler(request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	page, ok := request.QueryStringParameters["page"]
	if !ok || len(page) == 0 {
		page = "1"
	}

	cachedPage, ok := cache[page]
	if ok {
		cacheAge := time.Now().Sub(cachedPage.TimeLastUpdated)
		if cacheAge.Seconds() < 60 {
			fmt.Printf("Retrieved schedule from cache. CacheAge is %f\n", cacheAge.Seconds())
			return events.APIGatewayProxyResponse{
				Body:       cachedPage.Schedule,
				StatusCode: http.StatusOK,
				Headers:    map[string]string{"Content-Type": "application/json"},
			}, nil
		}
	}

	schedule, err := getScheduleFromDb(page)
	if err != nil {
		return events.APIGatewayProxyResponse{}, err
	} else if len(schedule) == 0 {
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusNotFound,
			Body:       fmt.Sprintf("Schedule page %s was not found", page),
		}, nil
	}

	cache[page] = CachedSchedulePage{
		Schedule:        schedule,
		TimeLastUpdated: time.Now(),
	}

	return events.APIGatewayProxyResponse{
		Body:       schedule,
		StatusCode: http.StatusOK,
		Headers:    map[string]string{"Content-Type": "application/json"},
	}, nil
}

func getScheduleFromDb(page string) (string, error) {
	input := &dynamodb.GetItemInput{
		TableName: aws.String("Schedule"),
		Key: map[string]*dynamodb.AttributeValue{
			"page": {
				N: aws.String(page),
			},
		},
	}
	result, err := db.GetItem(input)
	if err != nil {
		common.CheckDbResponseError(err)
		return "", err
	} else if result.Item == nil {
		return "", nil
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
