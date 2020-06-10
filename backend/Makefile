# These environment variables must be set for deployment to work.
S3_BUCKET := lol-vigil

# Common values used throughout the Makefile, not intended to be configured.
TEMPLATE = template.yaml
PACKAGED_TEMPLATE = packaged.yaml
STACK_NAME = lol-vigil
REGION = us-east-1
ZIPPER = ${GOPATH}\bin\build-lambda-zip.exe

.PHONY: clean
clean:
	rm -f hello_world update_schedule get_schedule $(PACKAGED_TEMPLATE)

.PHONY: install
install:
	go get ./...

hello_world: hello-world
	go build -o hello_world ./hello-world

update_schedule: updateSchedule
	env GOOS=linux GOARCH=amd64 go build -o update_schedule ./updateSchedule
	$(ZIPPER) -o update_schedule.zip update_schedule

get_schedule: getSchedule
	go build -o get_schedule ./getSchedule

.PHONY: lambda
lambda: update_schedule
	env GOOS=linux GOARCH=amd64 $(MAKE) hello_world
	env GOOS=linux GOARCH=amd64 $(MAKE) get_schedule
	$(ZIPPER) -o hello_world.zip hello_world
	$(ZIPPER) -o get_schedule.zip get_schedule

.PHONY: build
build: lambda

.PHONY: testUpdateSchedule
testUpdateSchedule: update_schedule
	sam local invoke 'UpdateScheduleFunction'

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