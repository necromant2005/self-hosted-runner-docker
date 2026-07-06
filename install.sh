#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${APP_DIR}/.env"
ENV_EXAMPLE="${APP_DIR}/.env.example"
RAW_BASE_URL="https://raw.githubusercontent.com/necromant2005/self-hosted-runner-docker/main"
RUNNER_DIR="/opt/github-runner"
RUNNER_WORK_DIR="${RUNNER_DIR}/work"
DEPLOY_DIR="/opt/deploy"
RUNNER_UID="1000"
RUNNER_GID="1000"
USE_SUDO_DOCKER=0

log() {
  printf '%s\n' "$*"
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

need_sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    return 1
  fi

  command -v sudo >/dev/null 2>&1 || fail "sudo is required when not running as root"
  return 0
}

run_root() {
  if need_sudo; then
    sudo "$@"
  else
    "$@"
  fi
}

check_docker() {
  command -v docker >/dev/null 2>&1 || fail "docker is required"

  if docker compose version >/dev/null 2>&1; then
    USE_SUDO_DOCKER=0
  elif command -v sudo >/dev/null 2>&1 && sudo docker compose version >/dev/null 2>&1; then
    USE_SUDO_DOCKER=1
  else
    fail "Docker Compose v2 is required"
  fi

  log "Docker and Docker Compose v2 are available."
}

docker_cmd() {
  if [ "$USE_SUDO_DOCKER" -eq 1 ]; then
    sudo docker "$@"
  else
    docker "$@"
  fi
}

download_if_missing() {
  local file="$1"
  local target="${APP_DIR}/${file}"

  if [ -f "$target" ]; then
    return
  fi

  command -v curl >/dev/null 2>&1 || fail "curl is required to download ${file}"
  log "Downloading ${file}..."
  curl -fsSL "${RAW_BASE_URL}/${file}" -o "$target"
}

prepare_project_files() {
  download_if_missing "Dockerfile"
  download_if_missing "docker-compose.yml"
  download_if_missing "entrypoint.sh"
  download_if_missing ".env.example"
  chmod +x "${APP_DIR}/entrypoint.sh"
}

prepare_directories() {
  log "Preparing host directories..."
  run_root mkdir -p "$RUNNER_WORK_DIR" "$DEPLOY_DIR"
  run_root chown -R "${RUNNER_UID}:${RUNNER_GID}" "$RUNNER_DIR"
}

prepare_env_file() {
  if [ -f "$ENV_FILE" ]; then
    log ".env already exists."
    return
  fi

  [ -f "$ENV_EXAMPLE" ] || fail ".env.example not found"
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  chmod 0600 "$ENV_FILE"
  log "Created .env from .env.example."
}

env_value() {
  local key="$1"
  grep -E "^${key}=" "$ENV_FILE" | tail -n 1 | cut -d '=' -f 2-
}

env_ready() {
  local repo_url runner_token

  repo_url="$(env_value REPO_URL || true)"
  runner_token="$(env_value RUNNER_TOKEN || true)"

  [ -n "$repo_url" ] || return 1
  [ -n "$runner_token" ] || return 1
  [ "$repo_url" != "https://github.com/OWNER/REPOSITORY" ] || return 1
  [ "$runner_token" != "NEW_TOKEN_FROM_GITHUB_UI" ] || return 1
}

start_runner() {
  log "Building and starting the runner..."
  cd "$APP_DIR"
  docker_cmd compose build
  docker_cmd compose up -d
}

main() {
  local rerun_command

  check_docker
  prepare_project_files
  prepare_directories
  prepare_env_file

  rerun_command="./install.sh"

  if ! env_ready; then
    cat <<EOF

Setup is ready.

Edit ${ENV_FILE} and set:
  REPO_URL=https://github.com/OWNER/REPOSITORY
  RUNNER_TOKEN=<new token from GitHub UI>

Then run this script again:
  ${rerun_command}
EOF
    exit 0
  fi

  start_runner

  cat <<EOF

Runner started.

Watch logs:
  docker logs -f github-runner
EOF
}

main "$@"
