#!/usr/bin/env bash

set -ex

docker build -t london.alexswilliams.co.uk:5000/fluentd-es:latest .
docker push london.alexswilliams.co.uk:5000/fluentd-es:latest
