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
	"time"
)

var (
	db = common.ConnectToDynamoDb()
)

func handler(snsEvent events.SNSEvent) {
	for _, event := range snsEvent.Records {
		gameDetails, err := common.UnmarshalGameDetails([]byte(event.SNS.Message))
		if err != nil {
			log.Printf("Error unmarshalling gameAlarms details: %s\n", err)
			return
		}

		gameAlarms, gameTimestamps := getGameAlarmsAndTimestamps(gameDetails)
		if gameAlarms == nil || gameTimestamps == nil {
			continue
		}

		gameNumber, _ := strconv.Atoi(gameDetails.GameNumber)

		gameStartTime, err := time.Parse(time.RFC3339, gameTimestamps["gameBegins"].(string))
		if err != nil {
			continue
		}
		firstBloodTime, err := time.Parse(time.RFC3339, gameTimestamps["firstBlood"].(string))
		if err != nil {
			continue
		}

		// Iterates through map of alarms (+GameStartTime)
		for key, val := range gameAlarms {
			if val == nil {
				break
			}
			alarmMap := val.(map[string]interface{})

			alarm := common.GameAlarm{
				GameNumber:       gameNumber,
				HasBeenTriggered: alarmMap["hasBeenTriggered"].(bool),
				Trigger:          alarmMap["trigger"].(string),
				Delay:            int(alarmMap["delay"].(float64)),
			}

			if alarm.HasBeenTriggered {
				continue
			}

			currentTime := time.Now()
			delay := time.Duration(alarm.Delay) * time.Minute

			fmt.Printf("DeviceID: %s\tAlarm: %+v\tDelay: %s\n", key, alarm, delay)

			switch alarm.Trigger {
			case "gameBegins":
				if !gameStartTime.IsZero() && currentTime.Sub(gameStartTime) >= delay {
					// todo: SNS
					println("Game Begins Trigger")
				}
			case "firstBlood":
				if !firstBloodTime.IsZero() && currentTime.Sub(firstBloodTime) >= delay {
					// todo: SNS
					println("First Blood Trigger")
				}
			}
		}
	}
}

func getMatchAlarmsAndTimestamps(matchID string) (interface{}, interface{}, error) {
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
		return nil, nil, err
	} else if result.Item == nil {
		return nil, nil, nil
	}

	type Item struct {
		GameAlarms     interface{} `json:"gameAlarms"`
		GameTimestamps interface{} `json:"gameTimestamps"`
	}
	item := Item{}
	err = dynamodbattribute.UnmarshalMap(result.Item, &item)
	if err != nil {
		return nil, nil, err
	}

	return item.GameAlarms, item.GameTimestamps, nil
}

func getGameAlarmsAndTimestamps(gameDetails common.GameDetails) (map[string]interface{}, map[string]interface{}) {
	matchAlarms, matchTimestamps, err := getMatchAlarmsAndTimestamps(gameDetails.MatchID)
	if err != nil {
		log.Printf("Error retrieving match %s from database: %s\n", gameDetails.MatchID, err)
	} else if matchAlarms == nil || matchTimestamps == nil {
		return nil, nil
	}

	matchAlarmsMap := matchAlarms.(map[string]interface{})
	if matchAlarmsMap[gameDetails.GameNumber] == nil {
		return nil, nil
	}

	matchTimestampsMap := matchTimestamps.(map[string]interface{})
	if matchTimestampsMap[gameDetails.GameNumber] == nil {
		return nil, nil
	}

	return matchAlarmsMap[gameDetails.GameNumber].(map[string]interface{}),
		matchTimestampsMap[gameDetails.GameNumber].(map[string]interface{})
}

func main() {
	lambda.Start(handler)
}
