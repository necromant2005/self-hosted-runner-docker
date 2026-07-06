# GitHub Self-Hosted Runner Docker

Local Docker setup for a GitHub Actions self-hosted runner.

It can run `docker` and `docker compose` jobs against the host Docker daemon through `/var/run/docker.sock`.

## Files

```text
.
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── .env.example
└── README.md
```

## Requirements

- Docker
- Docker Compose v2
- A GitHub repository runner registration token

Create the host directories used by the runner:

```bash
sudo mkdir -p /opt/github-runner/work /opt/deploy
sudo chown -R 1000:1000 /opt/github-runner
```

## Configuration

Copy the example environment file:

```bash
cp .env.example .env
```

Put the target repository URL and a fresh runner token from the GitHub UI into `.env`:

```bash
REPO_URL=https://github.com/OWNER/REPOSITORY
RUNNER_TOKEN=NEW_TOKEN_FROM_GITHUB_UI
```

The real `.env` file is ignored by git.

The runner settings live in `docker-compose.yml`:

```yaml
REPO_URL: "${REPO_URL}"
RUNNER_NAME: "dnipro-docker-runner"
RUNNER_WORKDIR: "/runner/_work"
```

## Start

Build and start the runner:

```bash
docker compose build
docker compose up -d
```

Watch logs:

```bash
docker logs -f github-runner
```

## Stop

Stop the container:

```bash
docker compose down
```

The entrypoint removes the runner registration on container shutdown when GitHub accepts the current token.

## Notes

- The container mounts `/var/run/docker.sock`, so jobs can control Docker on the host.
- Use SSH to the host for host-level operations such as `systemctl`, `apt`, or `reboot`.
- Runner work files are stored on the host in `/opt/github-runner/work`.
- `/opt/deploy` is mounted into the container for deployment scripts or artifacts.
