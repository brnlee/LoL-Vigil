package main

import (
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"github.com/brnlee/LoL-Vigil/common"
	"log"
	"strconv"
)

var (
	db = common.ConnectToDynamoDb()
)

func handler(snsEvent events.SNSEvent) {
	for _, event := range snsEvent.Records {
		gameDetails, err := common.UnmarshalGameDetails([]byte(event.SNS.Message))
		if err != nil {
			log.Printf("Error unmarshalling game details: %s\n", err)
			return
		}

		alarms := getGameAlarms(gameDetails)
		if alarms == nil {
			continue
		}

		gameNumber, _ := strconv.Atoi(gameDetails.GameNumber)

		for deviceID, alarmInterface := range alarms {
			if alarmInterface == nil {
				break
			}
			alarmMap := alarmInterface.(map[string]interface{})

			alarm := common.GameAlarm{
				GameNumber:       gameNumber,
				HasBeenTriggered: alarmMap["hasBeenTriggered"].(bool),
				Trigger:          alarmMap["trigger"].(string),
				Delay:            int(alarmMap["delay"].(float64)),
			}
			fmt.Printf("%s\t%+v\n", deviceID, alarm)
			if alarm.HasBeenTriggered {
				continue
			}

		}
	}
}

func getGames(matchID string) (interface{}, error) {
	input := &dynamodb.GetItemInput{
		TableName: aws.String("Matches"),
		Key: map[string]*dynamodb.AttributeValue{
			"id": {
				N: aws.String(matchID),
			},
		},
	}
	result, err := db.GetItem(input)
	if err != nil {
		common.CheckDbResponseError(err)
		return common.Match{}, err
	} else if result.Item == nil {
		return common.Match{}, nil
	}

	type Item struct {
		Games interface{} `json:"games"`
	}
	item := Item{}
	err = dynamodbattribute.UnmarshalMap(result.Item, &item)
	if err != nil {
		return common.Match{}, err
	}

	return item.Games, nil
}

func getGameAlarms(gameDetails common.GameDetails) map[string]interface{} {
	games, err := getGames(gameDetails.MatchID)
	if err != nil {
		log.Printf("Error retrieving match %s from database: %s\n", gameDetails.MatchID, err)
	} else if games == nil {
		return nil
	}

	gamesMap := games.(map[string]interface{})
	if gamesMap[gameDetails.GameNumber] == nil {
		return nil
	}

	alarms := gamesMap[gameDetails.GameNumber].(map[string]interface{})
	if alarms == nil {
		return nil
	}

	return alarms
}

func main() {
	lambda.Start(handler)
}
