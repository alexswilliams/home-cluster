#!/usr/bin/env bash

set -ex

tag="$(grep 'FROM.*' Dockerfile | sed 's/FROM //' | sed 's#.*/##' | sed 's/:/-/')--$(date +%Y%m%d-%H%M)"

docker build \
    -t london.alexswilliams.co.uk:5000/fluentd-custom:$tag \
    --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
    --build-arg VCS_REF=$(git rev-parse --short HEAD) \
    .
docker push london.alexswilliams.co.uk:5000/fluentd-custom:$tag
