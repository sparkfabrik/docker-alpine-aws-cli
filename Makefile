AUTHOR ?= sparkfabrik
IMAGE_NAME ?= docker-alpine-aws-cli
PLATFORM ?= "linux/amd64"
LATEST_VERSION ?= 2.31.17-alpine3.20

build: build-2.31.17-3.20

# To keep the number of builds low, we only keep the latest two versions of the AWS CLI
build-2.31.17-3.20: AWS_CLI_VERSION="2.31.17"
build-2.31.17-3.20: PYTHON_VERSION="3.12.4"
build-2.31.17-3.20: ALPINE_VERSION="3.20"
build-2.31.17-3.20: build-template

build-2.31.17-3.19: AWS_CLI_VERSION="2.31.17"
build-2.31.17-3.19: PYTHON_VERSION="3.12.4"
build-2.31.17-3.19: ALPINE_VERSION="3.19"
build-2.31.17-3.19: build-template

build-2.25.6-3.20: AWS_CLI_VERSION="2.25.6"
build-2.25.6-3.20: PYTHON_VERSION="3.12.4"
build-2.25.6-3.20: ALPINE_VERSION="3.20"
build-2.25.6-3.20: build-template

build-2.25.6-3.19: AWS_CLI_VERSION="2.25.6"
build-2.25.6-3.19: PYTHON_VERSION="3.12.4"
build-2.25.6-3.19: ALPINE_VERSION="3.19"
build-2.25.6-3.19: build-template

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
