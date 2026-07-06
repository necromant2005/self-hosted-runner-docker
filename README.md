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

Docker must already be installed on the server. The installer checks that `docker` and `docker compose` are available and enables Docker autostart with `systemctl` when available.

## Installation

1. Download all required files:

```bash
sudo mkdir -p /opt/github-runner
cd /opt/github-runner
sudo curl -fsSL https://raw.githubusercontent.com/necromant2005/self-hosted-runner-docker/main/install.sh -o install.sh
sudo chmod +x install.sh
sudo ./install.sh
```

The downloaded installer creates the rest of the required files in `/opt/github-runner`.

2. Add repository URL and runner token to the config:

```bash
sudo nano /opt/github-runner/.env
```

Put the target repository URL and a fresh runner token from the GitHub UI into `.env`.

Example:

```bash
REPO_URL=https://github.com/OWNER/REPOSITORY
RUNNER_TOKEN=NEW_TOKEN_FROM_GITHUB_UI
```

Where to get the values:

- `REPO_URL`: open your GitHub repository and copy the repository URL, for example `https://github.com/OWNER/REPOSITORY`.
- `RUNNER_TOKEN`: open `Repo -> Settings -> Actions -> Runners -> New self-hosted runner`, select Linux, and copy the generated registration token from the GitHub command.

3. Start the service:

```bash
cd /opt/github-runner
sudo docker compose build
sudo docker compose up -d
```

The real `.env` file is ignored by git.

The runner settings live in `docker-compose.yml`:

```yaml
REPO_URL: "${REPO_URL}"
RUNNER_NAME: "dnipro-docker-runner"
RUNNER_WORKDIR: "/runner/_work"
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
- Installation files and runner work files are stored on the host under `/opt/github-runner`.
- `/opt/deploy` is mounted into the container for deployment scripts or artifacts.
