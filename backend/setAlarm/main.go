package main

import (
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"github.com/brnlee/LoL-Vigil/common"
	"github.com/tidwall/gjson"
	"log"
	"net/http"
	"strconv"
)

//func (r *Alarm) MarshalGameDetails() ([]byte, error) {
//	return json.MarshalGameDetails(r)
//}

var (
	db = common.ConnectToDynamoDb()
)

func handler(request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.SetFlags(log.Lshortfile)

	alarmRequest, err := UnmarshalSetAlarmRequest(request.Body)
	if err != nil {
		log.Println("Error unmarshalling alarm request", err)
		return createResponse("", http.StatusBadRequest), nil
	}

	err = updateAlarmInDB(alarmRequest)
	if err != nil {
		log.Println("Error updating alarm in DB")
		return createResponse("", http.StatusInternalServerError), nil
	}

	return createResponse("Set alarm", http.StatusOK), nil
}

func UnmarshalSetAlarmRequest(data string) (common.Alarm, error) {
	gjson.Get(data, "deviceID")
	fields := gjson.GetMany(data, "deviceID", "matchID", "gameAlarms")
	for _, field := range fields {
		if !field.Exists() {
			return common.Alarm{}, fmt.Errorf("request did not include all required arguments")
		}
	}

	gameAlarmsResult := fields[2].Array()
	gameAlarms := make([]common.GameAlarm, len(gameAlarmsResult))
	for i, alarmResult := range gameAlarmsResult {
		alarm := alarmResult.Map()
		gameAlarms[i] = common.GameAlarm{
			GameNumber:       int(alarm["gameNumber"].Int()),
			Trigger:          alarm["trigger"].String(),
			Delay:            int(alarm["delay"].Int()),
			HasBeenTriggered: false,
		}
	}

	return common.Alarm{
		DeviceID:   fields[0].String(),
		MatchID:    fields[1].String(),
		GameAlarms: gameAlarms,
	}, nil
}

func createResponse(body string, statusCode int) events.APIGatewayProxyResponse {
	return events.APIGatewayProxyResponse{
		Body:       body,
		StatusCode: statusCode,
		Headers:    map[string]string{"Content-Type": "application/json"},
	}
}

func updateAlarmInDB(request common.Alarm) error {
	updateExpression := "SET "

	alarmAttributeNames := make(map[string]*string)
	alarmAttributeNames["#deviceID"] = aws.String(request.DeviceID)

	alarmAttributeValues := make(map[string]*dynamodb.AttributeValue)

	for _, alarm := range request.GameAlarms {
		alarmJson, err := dynamodbattribute.Marshal(alarm)
		if err != nil {
			log.Println("Error marshalling alarm request", err)
			return err
		}

		gameNumberKey := fmt.Sprintf("#game%d", alarm.GameNumber)
		alarmAttributeNames[gameNumberKey] = aws.String(strconv.Itoa(alarm.GameNumber))

		gameAlarmKey := fmt.Sprintf(":game%dAlarm", alarm.GameNumber)
		alarmAttributeValues[gameAlarmKey] = alarmJson

		updateExpression += fmt.Sprintf("games.%s.#deviceID = %s", gameNumberKey, gameAlarmKey)
		if alarm.GameNumber != len(request.GameAlarms) {
			updateExpression += ", "
		}
	}
	//fmt.Printf("%+v\n%+v\n%s\n", alarmAttributeNames, alarmAttributeValues, updateExpression)

	input := &dynamodb.UpdateItemInput{
		TableName: aws.String("Matches"),
		Key: map[string]*dynamodb.AttributeValue{
			"id": {
				N: aws.String(request.MatchID),
			},
		},
		ExpressionAttributeNames:  alarmAttributeNames,
		ExpressionAttributeValues: alarmAttributeValues,
		UpdateExpression:          aws.String(updateExpression),
	}
	_, err := db.UpdateItem(input)
	common.CheckDbResponseError(err)
	return err
}

func main() {
	lambda.Start(handler)
}
