package main

import (
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/tidwall/gjson"
	"log"
	"net/http"
)

//func (r *SetAlarmRequest) Marshal() ([]byte, error) {
//	return json.Marshal(r)
//}

type SetAlarmRequest struct {
	DeviceID   string `json:"deviceID"`
	MatchID    string `json:"matchID"`
	GameNumber int64  `json:"gameNumber"`
	Trigger    string `json:"trigger"`
	Delay      int64  `json:"delay"`
}

func handler(request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.SetFlags(log.Lshortfile)

	alarmRequest, err := UnmarshalSetAlarmRequest(request.Body)
	if err != nil {
		log.Println("Error unmarshalling alarm request")
		return createResponse("", http.StatusBadRequest), nil
	}
	fmt.Printf("%+v\n", alarmRequest)

	return createResponse("Set alarm", http.StatusOK), nil
}

func UnmarshalSetAlarmRequest(data string) (SetAlarmRequest, error) {
	gjson.Get(data, "deviceID")
	fields := gjson.GetMany(data, "deviceID", "matchID", "gameNumber", "trigger", "delay")
	for _, field := range fields {
		if !field.Exists() {
			return SetAlarmRequest{}, fmt.Errorf("request did not include all required arguments")
		}
	}

	return SetAlarmRequest{
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

func main() {
	lambda.Start(handler)
}
