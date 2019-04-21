#!/usr/bin/env bash

kubectl delete configmap grafana-dashboards
kubectl create configmap grafana-dashboards --from-file=./dashboards
