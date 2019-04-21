FROM alpine:3.9.3

RUN apk --no-cache add py3-pip jq groff && \
    pip3 install awscli --upgrade && \
    adduser -D -h /home/awsuser awsuser

USER awsuser
WORKDIR /home/awsuser

ENV AWS_DEFAULT_OUTPUT=json
