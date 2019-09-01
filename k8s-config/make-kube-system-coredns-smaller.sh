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
            memory: 64Mi
            cpu: 40m
          requests:
            memory: 64Mi
            cpu: 40m
'

