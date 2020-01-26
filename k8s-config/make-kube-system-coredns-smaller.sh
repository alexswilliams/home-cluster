#!/usr/bin/env bash

kubectl -n kube-system patch deploy/coredns -p '
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: coredns
        resources:
          limits:
            memory: "170Mi"
            cpu: "100m"
          requests:
            memory: "16Mi"
            cpu: "10m"
'

