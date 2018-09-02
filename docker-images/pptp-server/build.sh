#!/usr/bin/env bash

docker build -t docker-registry-service:5000/pptp-server:latest .
docker push docker-registry-service:5000/pptp-server
