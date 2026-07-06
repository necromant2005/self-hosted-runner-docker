FROM ubuntu:24.04

ARG RUNNER_VERSION=2.325.0
ARG TARGETARCH
ARG RUNNER_UID=1000
ARG RUNNER_GID=1000

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    jq \
    git \
    sudo \
    tar \
    unzip \
    iputils-ping \
    openssh-client \
    docker.io \
    docker-compose-v2 \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g "${RUNNER_GID}" runner \
    && useradd -m -u "${RUNNER_UID}" -g "${RUNNER_GID}" -s /bin/bash runner \
    && usermod -aG sudo,docker runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner \
    && chmod 0440 /etc/sudoers.d/runner

WORKDIR /home/runner/actions-runner

RUN if [ "$TARGETARCH" = "arm64" ]; then ARCH="arm64"; else ARCH="x64"; fi \
    && curl -L -o actions-runner.tar.gz \
      "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz" \
    && tar xzf actions-runner.tar.gz \
    && rm actions-runner.tar.gz \
    && ./bin/installdependencies.sh || true \
    && chown -R runner:runner /home/runner/actions-runner

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

USER runner

ENTRYPOINT ["/entrypoint.sh"]
