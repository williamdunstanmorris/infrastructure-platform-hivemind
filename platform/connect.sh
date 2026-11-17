#!/usr/bin/env bash
# Opens an SSM tunnel to the private EKS API and writes a repo-local kubeconfig.
# AWS_PROFILE / AWS_REGION / KUBECONFIG come from the repo .envrc (direnv).
# Keep this running; use kubectl/helm/terraform from another terminal in the repo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_DIR="$SCRIPT_DIR/../infrastructure"
KUBE_CONFIG="$SCRIPT_DIR/.kubeconfig"
CLUSTER="Main"
REGION="${AWS_REGION:-eu-central-1}"
LOCAL_PORT=8443

rm -f "$KUBE_CONFIG"

# Both change on every destroy/apply, so read them from state instead of hardcoding.
HOST=$(terraform -chdir="$INFRA_DIR" output -raw eks_api_host)
TARGET=$(terraform -chdir="$INFRA_DIR" output -raw bastion_instance_id)

aws eks update-kubeconfig \
  --name "$CLUSTER" \
  --region "$REGION" \
  --kubeconfig "$KUBE_CONFIG" \
  --alias "hivemind-$CLUSTER"

# Point the cluster at the local end of the tunnel; keep TLS verification against the real hostname.
kubectl config set-cluster \
  --kubeconfig "$KUBE_CONFIG" \
  "$(kubectl --kubeconfig "$KUBE_CONFIG" config view -o jsonpath='{.clusters[0].name}')" \
  --server="https://localhost:$LOCAL_PORT" \
  --tls-server-name="$HOST"

aws ssm start-session \
  --target "$TARGET" \
  --region "$REGION" \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{\"host\":[\"$HOST\"],\"portNumber\":[\"443\"],\"localPortNumber\":[\"$LOCAL_PORT\"]}"
