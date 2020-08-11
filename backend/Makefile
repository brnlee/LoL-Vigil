# These environment variables must be set for deployment to work.
S3_BUCKET := lol-vigil

# Common values used throughout the Makefile, not intended to be configured.
TEMPLATE = template.yaml
PACKAGED_TEMPLATE = packaged.yaml
STACK_NAME = lol-vigil
REGION = us-east-1
ZIPPER = ${GOPATH}\bin\build-lambda-zip.exe

.PHONY: createDb
createDb:
	docker run -d -v F:\Users\Brian\go\src\github.com\brnlee\LoL-Vigil\backend\dynamodb_local_db -p 8000:8000 --network lambda-local --name dynamodb cnadiminti/dynamodb-local

.PHONY: createMatches
createMatches: deleteMatches
	aws dynamodb create-table --table-name Matches --attribute-definitions AttributeName=id,AttributeType=N --key-schema AttributeName=id,KeyType=HASH --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 --endpoint-url http://localhost:8000

.PHONY: deleteMatches
deleteMatches:
	aws dynamodb delete-table --table-name Matches --endpoint-url http://localhost:8000

.PHONY: scanMatches
scanMatches:
	aws dynamodb scan --table-name Matches --endpoint-url http://localhost:8000

.PHONY: createSchedule
createSchedule: deleteSchedule
	aws dynamodb create-table --table-name Schedule --attribute-definitions AttributeName=page,AttributeType=N --key-schema AttributeName=page,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 --endpoint-url http://localhost:8000

.PHONY: deleteSchedule
deleteSchedule:
	aws dynamodb delete-table --table-name Schedule --endpoint-url http://localhost:8000

.PHONY: scanSchedule
scanSchedule:
	aws dynamodb scan --table-name Schedule --endpoint-url http://localhost:8000

.PHONY: startdb
startdb: createMatches createSchedule
	docker start dynamodb

.PHONY: clean
clean:
	rm -f update_schedule get_schedule $(PACKAGED_TEMPLATE)

update_schedule: updateSchedule
	env GOOS=linux GOARCH=amd64 go build -o update_schedule ./updateSchedule
	$(ZIPPER) -o update_schedule.zip update_schedule

get_schedule: getSchedule
	env GOOS=linux GOARCH=amd64 go build -o get_schedule ./getSchedule
	$(ZIPPER) -o get_schedule.zip get_schedule

get_leagues: getLeagues
	env GOOS=linux GOARCH=amd64 go build -o get_leagues ./getLeagues
	$(ZIPPER) -o get_leagues.zip get_leagues

set_alarm: setAlarm
	env GOOS=linux GOARCH=amd64 go build -o set_alarm ./setAlarm
	$(ZIPPER) -o set_alarm.zip set_alarm

check_match_status: checkMatchStatus
	env GOOS=linux GOARCH=amd64 go build -o check_match_status ./checkMatchStatus
	$(ZIPPER) -o check_match_status.zip check_match_status

send_alarm_notifications: sendAlarmNotifications
	env GOOS=linux GOARCH=amd64 go build -o send_alarm_notifications ./sendAlarmNotifications
	$(ZIPPER) -o send_alarm_notifications.zip send_alarm_notifications

.PHONY: testUpdateSchedule
testUpdateSchedule: update_schedule
	sam local invoke 'UpdateScheduleFunction' --docker-network lambda-local

.PHONY: testGetSchedule
testGetSchedule: get_schedule
	sam local invoke 'GetScheduleFunction' --docker-network lambda-local

.PHONY: testGetLeagues
testGetLeagues: get_leagues
	sam local invoke 'GetLeaguesFunction' --docker-network lambda-local

.PHONY: testSetAlarm
testGetLeagues: set_alarm
	sam local invoke 'SetAlarmFunction' --docker-network lambda-local

.PHONY: testCheckMatchStatus
testCheckMatchStatus: check_match_status
	sam local invoke 'CheckMatchStatusFunction' --docker-network lambda-local

.PHONY: testSendAlarmNotifications
testSendAlarmNotifications: send_alarm_notifications
	sam local invoke 'SendAlarmNotificationsFunction' --event SNSEvent.json --docker-network lambda-local

.PHONY: build
build: update_schedule get_schedule get_leagues set_alarm check_match_status send_alarm_notifications

.PHONY: run
run: build
	sam local start-api --docker-network lambda-local

.PHONY: package
package: build
	sam package --template-file $(TEMPLATE) --s3-bucket $(S3_BUCKET) --output-template-file $(PACKAGED_TEMPLATE)

.PHONY: deploy
deploy: package
	sam deploy --stack-name $(STACK_NAME) --region $(REGION) --template-file $(PACKAGED_TEMPLATE) --capabilities CAPABILITY_IAM --s3-bucket $(S3_BUCKET)

.PHONY: teardown
teardown:
	aws cloudformation delete-stack --stack-name $(STACK_NAME)