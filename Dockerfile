ARG PYTHON_VERSION=3.11.9
ARG ALPINE_VERSION=3.19

FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION} as builder

ARG AUTHOR
ARG PYTHON_VERSION=3.11.9
ARG ALPINE_VERSION=3.19
ARG IMAGE_NAME=spark-alpine-aws-cli
ARG AWS_CLI_VERSION=2.16.7

# Build process
# If you want to see the AWS CLI v2 documentation, remember to go to the `v2` branch.
RUN apk add --no-cache git unzip groff build-base libffi-dev cmake
WORKDIR /
RUN git clone --single-branch --depth 1 -b ${AWS_CLI_VERSION} https://github.com/aws/aws-cli.git

WORKDIR /aws-cli
RUN python -m venv venv
RUN . venv/bin/activate
RUN scripts/installers/make-exe
RUN unzip -q dist/awscli-exe.zip
RUN aws/install --bin-dir /aws-cli-bin
RUN /aws-cli-bin/aws --version

RUN find /usr/local/aws-cli/v2/current/dist/awscli/data -name completions-1*.json -delete
RUN find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete

FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache bash groff

# Install AWS CLI v2 using the binary created in the builder stage
COPY --from=builder /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=builder /aws-cli-bin/ /usr/local/bin/
