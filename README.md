# GitHub Self-Hosted Runner Docker

Local Docker setup for a GitHub Actions self-hosted runner.

It can run `docker` and `docker compose` jobs against the host Docker daemon through `/var/run/docker.sock`.

## Files

```text
.
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── install.sh
├── .env.example
└── README.md
```

## Requirements

- Docker
- Docker Compose v2
- A GitHub repository runner registration token

Docker must already be installed on the server. The installer only checks that `docker` and `docker compose` are available.

Download the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/necromant2005/self-hosted-runner-docker/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

The downloaded installer creates the rest of the required files in the same directory and prepares the host directories under `/opt`.

Run the installer:

```bash
chmod +x install.sh
./install.sh
```

## Configuration

On the first run, the installer creates `.env` from `.env.example`.

Put the target repository URL and a fresh runner token from the GitHub UI into `.env`:

```bash
REPO_URL=https://github.com/OWNER/REPOSITORY
RUNNER_TOKEN=NEW_TOKEN_FROM_GITHUB_UI
```

Run the installer again:

```bash
./install.sh
```

The real `.env` file is ignored by git.

The runner settings live in `docker-compose.yml`:

```yaml
REPO_URL: "${REPO_URL}"
RUNNER_NAME: "dnipro-docker-runner"
RUNNER_WORKDIR: "/runner/_work"
```

## Start

The installer builds and starts the runner when `.env` is configured.

Manual start:

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
- The container `runner` user is created with UID/GID `1000:1000`; host work files are owned by the same IDs.
- Use SSH to the host for host-level operations such as `systemctl`, `apt`, or `reboot`.
- Runner work files are stored on the host in `/opt/github-runner/work`.
- `/opt/deploy` is mounted into the container for deployment scripts or artifacts.
