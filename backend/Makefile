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
	aws dynamodb create-table --table-name Matches --attribute-definitions AttributeName=id,AttributeType=N --key-schema AttributeName=id,KeyType=HASH --provisioned-throughput ReadCapacityUnits=25,WriteCapacityUnits=25 --endpoint-url http://localhost:8000

.PHONY: deleteMatches
deleteMatches:
	aws dynamodb delete-table --table-name Matches --endpoint-url http://localhost:8000

.PHONY: scanMatches
scanMatches:
	aws dynamodb scan --table-name Matches --endpoint-url http://localhost:8000

.PHONY: startdb
startdb:
	docker start dynamodb

.PHONY: clean
clean:
	rm -f update_schedule get_schedule $(PACKAGED_TEMPLATE)

update_schedule: updateSchedule
	env GOOS=linux GOARCH=amd64 go build -o update_schedule ./updateSchedule
	$(ZIPPER) -o update_schedule.zip update_schedule

get_schedule: getSchedule
	go build -o get_schedule ./getSchedule
	$(ZIPPER) -o get_schedule.zip get_schedule

.PHONY: testUpdateSchedule
testUpdateSchedule: update_schedule
	sam local invoke 'UpdateScheduleFunction' --docker-network lambda-local

.PHONY: build
build: update_schedule getSchedule

.PHONY: run
run: build
	sam local start-api

.PHONY: package
package: build
	sam package --template-file $(TEMPLATE) --s3-bucket $(S3_BUCKET) --output-template-file $(PACKAGED_TEMPLATE)

.PHONY: deploy
deploy: package
	sam deploy --stack-name $(STACK_NAME) --region $(REGION) --template-file $(PACKAGED_TEMPLATE) --capabilities CAPABILITY_IAM --s3-bucket $(S3_BUCKET)

.PHONY: teardown
teardown:
	aws cloudformation delete-stack --stack-name $(STACK_NAME)