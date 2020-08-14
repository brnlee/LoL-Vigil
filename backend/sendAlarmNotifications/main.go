package main

import (
	"encoding/json"
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"github.com/aws/aws-sdk-go/service/sns"
	"github.com/brnlee/LoL-Vigil/common"
	"log"
	"os"
	"strconv"
	"time"
)

var (
	db = common.ConnectToDynamoDb()
)

type SNSMessage struct {
	GCM string `json:"GCM"`
}

type GCMMessage struct {
	Data DataMessage `json:"data,omitempty"`
	//Notification NotificationMessaage `json:"notification,omitempty"`
}

type DataMessage struct {
	Message string `json:"message"`
}

//type NotificationMessaage struct {
//	Text string `json:"text"`
//}

func handler(snsEvent events.SNSEvent) {
	//hardcodedSendNotification()
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

		var gameStartTime time.Time
		var firstBloodTime time.Time

		if gameBegins, ok := gameTimestamps["gameBegins"]; ok {
			gameStartTime, err = time.Parse(time.RFC3339, gameBegins.(string))
			if err != nil {
				continue
			}
		}

		if firstBlood, ok := gameTimestamps["firstBlood"]; ok {
			firstBloodTime, err = time.Parse(time.RFC3339, firstBlood.(string))
			if err != nil {
				continue
			}
		}

		updateExpression := ""
		alarmAttributeNames := map[string]*string{
			"#hasBeenTriggered": aws.String("hasBeenTriggered"),
		}
		gameNumberKey := fmt.Sprintf("#game%d", gameNumber)
		alarmAttributeNames[gameNumberKey] = aws.String(gameDetails.GameNumber)

		//alarmAttributeNames["#deviceID"] = aws.String(request.DeviceID)
		deviceIndex := 0

		// Iterates through map of alarms (+GameStartTime)
		for deviceToken, gameAlarm := range gameAlarms {
			if gameAlarm == nil {
				break
			}
			alarmMap := gameAlarm.(map[string]interface{})

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

			log.Printf("Game Alarm\n\tDeviceID: %s\tAlarm: %+v\tDelay: %s\n", deviceToken, alarm, delay)

			switch alarm.Trigger {
			case "gameBegins":
				log.Println("Game Begins Trigger")
				if !(!gameStartTime.IsZero() && currentTime.Sub(gameStartTime) >= delay) {
					continue
				}
			case "firstBlood":
				log.Println("First Blood Trigger")
				if !(!firstBloodTime.IsZero() && currentTime.Sub(firstBloodTime) >= delay) {
					continue
				}
			}

			if sendNotification(deviceToken) {
				if updateExpression == "" {
					updateExpression = "SET "
				} else {
					updateExpression += ", "
				}

				// Set hasBeenTriggered to True
				deviceKey := fmt.Sprintf("#Device%d", deviceIndex)
				alarmAttributeNames[deviceKey] = aws.String(deviceToken)
				updateExpression += fmt.Sprintf("gameAlarms.%s.%s.#hasBeenTriggered = :true", gameNumberKey, deviceKey)
				deviceIndex += 1
			}
		}

		// Execute update expression to set alarms' hasBeenTriggered to True
		if updateExpression != "" {
			input := &dynamodb.UpdateItemInput{
				TableName: aws.String("Matches"),
				Key: map[string]*dynamodb.AttributeValue{
					"id": {
						N: aws.String(gameDetails.MatchID),
					},
				},
				ExpressionAttributeNames: alarmAttributeNames,
				ExpressionAttributeValues: map[string]*dynamodb.AttributeValue{
					":true": {
						BOOL: aws.Bool(true),
					},
				},
				UpdateExpression: aws.String(updateExpression),
			}
			_, err = db.UpdateItem(input)
			common.CheckDbResponseError(err)
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

func sendNotification(deviceToken string) bool {
	sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))

	svc := sns.New(sess)

	resp, err := svc.CreatePlatformEndpoint(&sns.CreatePlatformEndpointInput{
		PlatformApplicationArn: aws.String(os.Getenv("SNSApplicationARN")),
		Token:                  aws.String(deviceToken),
	})
	if err != nil {
		log.Printf("Error creating platform endpoint: %s\n", err)
		return false
	}

	gcmMessage := GCMMessage{
		Data: DataMessage{
			Message: "This is a test notification.",
		},
	}

	gcmMessageJson, err := json.Marshal(gcmMessage)
	if err != nil {
		log.Printf("Error marshalling GCMMessage: %s\n", err)
		return false
	}

	message := SNSMessage{
		GCM: string(gcmMessageJson),
	}

	messageJSON, err := json.Marshal(message)
	if err != nil {
		log.Printf("Error marshalling SNS message to JSON: %s\n", err)
		return false
	}

	input := &sns.PublishInput{
		Message:          aws.String(string(messageJSON)),
		MessageStructure: aws.String("json"),
		TargetArn:        aws.String(*resp.EndpointArn),
	}
	_, err = svc.Publish(input)
	if err != nil {
		log.Printf("Error publushing message: %s\n", err)
		return false
	}

	log.Printf("Sent notification to %s\n", deviceToken)
	return true
}

//func hardcodedSendNotification() {
//	sess := session.Must(session.NewSessionWithOptions(session.Options{
//		SharedConfigState: session.SharedConfigEnable,
//	}))
//
//	svc := sns.New(sess)
//
//	resp, err := svc.CreatePlatformEndpoint(&sns.CreatePlatformEndpointInput{
//		PlatformApplicationArn: aws.String(os.Getenv("SNSApplicationARN")),
//		Token:                  aws.String(os.Getenv("TestToken")),
//	})
//	if err != nil {
//		log.Printf("Error creating platform endpoint: %s\n", err)
//		return
//	}
//
//	gcmMessage := GCMMessage{
//		Data: DataMessage{
//			Message: "This is a test notification.",
//		},
//	}
//
//	g, err := json.Marshal(gcmMessage)
//	if err != nil {
//		log.Printf("Error marshalling GCMMessage: %s\n", err)
//		return
//	}
//
//	message := SNSMessage{
//		GCM: string(g),
//	}
//
//	messageJSON, err := json.Marshal(message)
//	if err != nil {
//		log.Printf("Error marshalling GCM message to JSON: %s\n", err)
//		return
//	}
//
//	log.Println(string(messageJSON))
//
//	input := &sns.PublishInput{
//		Message:          aws.String(string(messageJSON)),
//		MessageStructure: aws.String("json"),
//		TargetArn:        aws.String(*resp.EndpointArn),
//	}
//	_, err = svc.Publish(input)
//	if err != nil {
//		log.Printf("Error publushing message: %s\n", err)
//		return
//	}
//}

func main() {
	lambda.Start(handler)
}
