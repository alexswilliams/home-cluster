#!/usr/bin/env bash

kubectl -n kube-system patch sa/default -p '
automountServiceAccountToken: false
'

