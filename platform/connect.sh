#!/usr/bin/env bash
set -euo pipefail

HOST=$(aws eks describe-cluster \
      --name 'Main' \
      --region 'eu-central-1' \
      --query cluster.endpoint \
      --output text \
      --profile hivemind)

HOST=${HOST#https://}

KUBE_CONFIG=.kubeconfig

aws eks update-kubeconfig \
    --name "Main" \
    --region eu-central-1 \
    --kubeconfig $KUBE_CONFIG \
    --profile hivemind

kubectl config set-cluster \
    --kubeconfig $KUBE_CONFIG "$(kubectl --kubeconfig $KUBE_CONFIG config view -o jsonpath='{.clusters[0].name}')" \
    --server=https://localhost:8443 \
    --tls-server-name="$HOST"

aws ssm start-session --target i-0fb5ae74f017694c0 --profile hivemind \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{\"host\":[\"$HOST\"],\"portNumber\":[\"443\"],\"localPortNumber\":[\"8443\"]}"
