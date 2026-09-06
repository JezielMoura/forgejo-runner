FROM node:24-slim

ENV DEBIAN_FRONTEND=noninteractive \
    NPM_CONFIG_PREFIX=/home/runner/.npm-global \
    DOTNET_ROOT=/usr/share/dotnet \
    DOTNET_NOLOGO=1 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
    PATH="/usr/share/dotnet:/usr/share/dotnet/tools:/home/runner/.dotnet/tools:/home/runner/.npm-global/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      buildah \
      fuse-overlayfs \
      libicu-dev \
      jq \
      gnupg \
      gettext-base \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
    && chmod +x /tmp/dotnet-install.sh \
    && /tmp/dotnet-install.sh --channel 10.0 --install-dir "${DOTNET_ROOT}" \
    && /tmp/dotnet-install.sh --channel 11.0 --quality preview --install-dir "${DOTNET_ROOT}" \
    && rm /tmp/dotnet-install.sh

RUN RUNNER_VERSION=$(curl -s 'https://data.forgejo.org/api/v1/repos/forgejo/runner/releases/latest' | jq -r .name | cut -c 2-) \
    && curl -fsSL -o /usr/local/bin/forgejo-runner \
      "https://code.forgejo.org/forgejo/runner/releases/download/v${RUNNER_VERSION}/forgejo-runner-${RUNNER_VERSION}-linux-amd64" \
    && chmod +x /usr/local/bin/forgejo-runner \
    && forgejo-runner -v

RUN KUBECTL_VERSION=$(curl -Ls https://dl.k8s.io/release/stable.txt) \
    && curl -fsSL -o /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x /usr/local/bin/kubectl \
    && kubectl version --client

RUN chmod u+s /usr/bin/newuidmap /usr/bin/newgidmap

RUN useradd --create-home --shell /bin/bash runner \
    && usermod --add-subuids 100000-165535 --add-subgids 100000-165535 runner \
    && mkdir -p /home/runner/.npm-global \
    && chown -R runner:runner /home/runner

WORKDIR /home/runner
USER runner

CMD ["forgejo-runner", "daemon", "-c", "/etc/forgejo-runner/config.yaml"]
