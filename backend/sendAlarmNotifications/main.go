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
			log.Printf("Error unmarshalling game details: %s\n", err)
			return
		}

		game := getGame(gameDetails)
		if game == nil {
			continue
		}

		gameNumber, _ := strconv.Atoi(gameDetails.GameNumber)
		gameStartTime, err := time.Parse(time.RFC3339, game["GameStartTime"].(string))
		if err != nil {
			continue
		}

		// Iterates through map of alarms (+GameStartTime)
		for key, val := range game {
			if key == "GameStartTime" {
				continue
			} else if val == nil {
				break
			}
			alarmMap := val.(map[string]interface{})

			alarm := common.GameAlarm{
				GameNumber:       gameNumber,
				HasBeenTriggered: alarmMap["hasBeenTriggered"].(bool),
				Trigger:          alarmMap["trigger"].(string),
				Delay:            int(alarmMap["delay"].(float64)),
			}
			fmt.Printf("%s\t%+v\t%s\n", key, alarm, time.Now().Sub(gameStartTime).String())
			if alarm.HasBeenTriggered {
				continue
			} else if alarm.Trigger == "gameBegins" && time.Now().Sub(gameStartTime) >= time.Duration(alarm.Delay)*time.Second {
				// todo: SNS
				println("WEEEEEEEEEEEEE")
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
		return nil, err
	} else if result.Item == nil {
		return nil, nil
	}

	type Item struct {
		Games interface{} `json:"games"`
	}
	item := Item{}
	err = dynamodbattribute.UnmarshalMap(result.Item, &item)
	if err != nil {
		return nil, err
	}

	return item.Games, nil
}

func getGame(gameDetails common.GameDetails) map[string]interface{} {
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

	return gamesMap[gameDetails.GameNumber].(map[string]interface{})
}

func main() {
	lambda.Start(handler)
}
