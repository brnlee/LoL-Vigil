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

//func (r *Alarm) Marshal() ([]byte, error) {
//	return json.Marshal(r)
//}

var (
	db = common.ConnectToDynamoDb()
)

func handler(request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.SetFlags(log.Lshortfile)

	alarmRequest, err := UnmarshalSetAlarmRequest(request.Body)
	if err != nil {
		log.Println("Error unmarshalling alarm request")
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
	fields := gjson.GetMany(data, "deviceID", "matchID", "gameNumber", "trigger", "delay")
	for _, field := range fields {
		if !field.Exists() {
			return common.Alarm{}, fmt.Errorf("request did not include all required arguments")
		}
	}

	return common.Alarm{
		DeviceID:   fields[0].String(),
		MatchID:    fields[1].String(),
		GameNumber: fields[2].Int(),
		Trigger:    fields[3].String(),
		Delay:      fields[4].Int(),
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
	alarmRequestJson, err := dynamodbattribute.Marshal(request)
	if err != nil {
		log.Println("Error marshalling alarm request", err)
		return err
	}

	input := &dynamodb.UpdateItemInput{
		TableName: aws.String("Matches"),
		Key: map[string]*dynamodb.AttributeValue{
			"id": {
				N: aws.String(request.MatchID),
			},
		},
		ExpressionAttributeNames: map[string]*string{
			"#gameNumber": aws.String(strconv.FormatInt(request.GameNumber, 10)),
			"#deviceID":   aws.String(request.DeviceID),
		},
		ExpressionAttributeValues: map[string]*dynamodb.AttributeValue{
			":alarm": alarmRequestJson,
		},
		UpdateExpression: aws.String("SET games.#gameNumber.#deviceID = :alarm"),
	}
	_, err = db.UpdateItem(input)
	common.CheckDbResponseError(err)
	return err
}

func main() {
	lambda.Start(handler)
}
