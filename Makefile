AUTHOR ?= sparkfabrik
IMAGE_NAME ?= docker-alpine-aws-cli
PLATFORM ?= "linux/amd64"
LATEST_VERSION ?= 2.41.1-alpine3.24

build: build-2.41.1-3.24

# To keep the number of builds low, we only keep the latest two versions of the AWS CLI
build-2.41.1-3.24: AWS_CLI_VERSION="2.41.1"
build-2.41.1-3.24: PYTHON_VERSION="3.12.16"
build-2.41.1-3.24: ALPINE_VERSION="3.24"
build-2.41.1-3.24: build-template

build-2.41.1-3.23: AWS_CLI_VERSION="2.41.1"
build-2.41.1-3.23: PYTHON_VERSION="3.12.16"
build-2.41.1-3.23: ALPINE_VERSION="3.23"
build-2.41.1-3.23: build-template

build-2.35.15-3.24: AWS_CLI_VERSION="2.35.15"
build-2.35.15-3.24: PYTHON_VERSION="3.12.16"
build-2.35.15-3.24: ALPINE_VERSION="3.24"
build-2.35.15-3.24: build-template

build-2.35.15-3.23: AWS_CLI_VERSION="2.35.15"
build-2.35.15-3.23: PYTHON_VERSION="3.12.16"
build-2.35.15-3.23: ALPINE_VERSION="3.23"
build-2.35.15-3.23: build-template

build-template:
	docker buildx build --load . \
		--platform "$(PLATFORM)" \
		--build-arg AUTHOR=$(AUTHOR) \
		--build-arg IMAGE_NAME=$(IMAGE_NAME) \
		--build-arg PYTHON_VERSION=$(PYTHON_VERSION) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg AWS_CLI_VERSION=$(AWS_CLI_VERSION) \
		-t $(AUTHOR)/$(IMAGE_NAME):$(AWS_CLI_VERSION)-alpine$(ALPINE_VERSION)

print-latest-image-tag:
	@echo $(LATEST_VERSION)
