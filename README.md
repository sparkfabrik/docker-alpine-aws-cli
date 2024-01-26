# spark-docker-alpine-aws-cli

Docker image for AWS-CLI v2 on Alpine Linux.

## Usage example

You can import the compiled binary created in this image in your Alpine Linux image.

```bash
FROM ghcr.io/sparkfabrik/docker-alpine-aws-cli:2.15.14-alpine3.18 as awscli

FROM alpine:3.18
# Install AWS CLI v2 using the binary builded in the awscli stage
COPY --from=awscli /usr/local/aws-cli/ /usr/local/aws-cli/
RUN ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws
```

In the final image you can run the `aws` topics using the AWS CLI v2.
