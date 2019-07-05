FROM alpine:3.10.0

ARG VCS_REF
ARG BUILD_DATE

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="AWS CLI" \
      org.label-schema.description="AWS CLI Tools" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/alexswilliams/home-cluster" \
      org.label-schema.schema-version="1.0"

RUN apk --no-cache add py3-pip groff && \
    pip3 install awscli --upgrade && \
    adduser -D -h /home/awsuser awsuser

USER awsuser
WORKDIR /home/awsuser

ENV AWS_DEFAULT_OUTPUT=json
