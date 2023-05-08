AUTHOR ?= sparkfabrik
IMAGE_NAME ?= docker-alpine-aws-cli
PLATFORM ?= "linux/amd64"

build: build-2.11.18-3.17

# To keep the number of builds low, we only keep the latest two versions of the AWS CLI
build-2.11.18-3.17: AWS_CLI_VERSION="2.11.18"
build-2.11.18-3.17: ALPINE_VERSION="3.17"
build-2.11.18-3.17: build-template

build-2.11.2-3.17: AWS_CLI_VERSION="2.11.2"
build-2.11.2-3.17: ALPINE_VERSION="3.17"
build-2.11.2-3.17: build-template

build-2.11.18-3.16: AWS_CLI_VERSION="2.11.18"
build-2.11.18-3.16: ALPINE_VERSION="3.16"
build-2.11.18-3.16: build-template

build-2.11.2-3.16: AWS_CLI_VERSION="2.11.2"
build-2.11.2-3.16: ALPINE_VERSION="3.16"
build-2.11.2-3.16: build-template

build-2.11.18-3.15: AWS_CLI_VERSION="2.11.18"
build-2.11.18-3.15: ALPINE_VERSION="3.15"
build-2.11.18-3.15: build-template

build-2.11.2-3.15: AWS_CLI_VERSION="2.11.2"
build-2.11.2-3.15: ALPINE_VERSION="3.15"
build-2.11.2-3.15: build-template

build-template:
	docker buildx build --load . \
		--platform "$(PLATFORM)" \
		--build-arg AUTHOR=$(AUTHOR) \
		--build-arg IMAGE_NAME=$(IMAGE_NAME) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg AWS_CLI_VERSION=$(AWS_CLI_VERSION) \
		-t $(AUTHOR)/$(IMAGE_NAME):$(AWS_CLI_VERSION)-alpine$(ALPINE_VERSION)
