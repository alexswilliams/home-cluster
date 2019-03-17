#!/usr/bin/env bash

set -ex

tag="$(grep 'FROM.*' Dockerfile | sed 's/FROM //' | sed 's#.*/##' | sed 's/:/-/')--$(date +%Y%m%d-%H%M)"

docker build -t london.alexswilliams.co.uk:5000/pptp-server:$tag .
docker push london.alexswilliams.co.uk:5000/pptp-server:$tag
