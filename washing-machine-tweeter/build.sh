#!/usr/bin/env bash

set -ex

tag="$(grep 'FROM.*' Dockerfile | sed 's/FROM //' | sed 's#.*/##' | sed 's/:/-/')--$(date +%Y%m%d-%H%M)"

docker build \
    -t london.alexswilliams.co.uk:5000/washing-tweeter:$tag \
    --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
    --build-arg VCS_REF=$(git rev-parse --short HEAD) \
    .

if [ -z "$1" ]; then
    docker push london.alexswilliams.co.uk:5000/washing-tweeter:$tag
fi
