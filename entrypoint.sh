#!/usr/bin/env bash
set -e

cd /home/runner/actions-runner

if [ -z "$REPO_URL" ]; then
  echo "REPO_URL is required"
  exit 1
fi

if [ -z "$RUNNER_TOKEN" ]; then
  echo "RUNNER_TOKEN is required"
  exit 1
fi

RUNNER_NAME="${RUNNER_NAME:-local-docker-runner}"
RUNNER_WORKDIR="${RUNNER_WORKDIR:-/runner/_work}"

cleanup() {
  echo "Removing runner..."
  ./config.sh remove --unattended --token "$RUNNER_TOKEN" || true
}

trap cleanup EXIT

if [ ! -f ".runner" ]; then
  ./config.sh \
    --unattended \
    --url "$REPO_URL" \
    --token "$RUNNER_TOKEN" \
    --name "$RUNNER_NAME" \
    --work "$RUNNER_WORKDIR" \
    --replace
fi

./run.sh
