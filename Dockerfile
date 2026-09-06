FROM node:24-slim

ENV DEBIAN_FRONTEND=noninteractive \
    NPM_CONFIG_PREFIX=/home/runner/.npm-global \
    DOTNET_ROOT=/usr/share/dotnet \
    DOTNET_NOLOGO=1 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
    PATH="/usr/share/dotnet:/usr/share/dotnet/tools:/home/runner/.dotnet/tools:/home/runner/.npm-global/bin:${PATH}"

RUN apt-get update && apt-get install -y ca-certificates curl git buildah fuse-overlayfs libicu-dev jq gnupg gettext-base

RUN curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
    && chmod +x /tmp/dotnet-install.sh \
    && /tmp/dotnet-install.sh --channel 10.0 --install-dir "${DOTNET_ROOT}" \
    && /tmp/dotnet-install.sh --channel 11.0 --quality preview --install-dir "${DOTNET_ROOT}" \
    && rm /tmp/dotnet-install.sh

RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') \
    && RUNNER_VERSION=$(curl -s 'https://data.forgejo.org/api/v1/repos/forgejo/runner/releases/latest' | jq -r .name | cut -c 2-) \
    && FORGEJO_URL="https://code.forgejo.org/forgejo/runner/releases/download/v${RUNNER_VERSION}/forgejo-runner-${RUNNER_VERSION}-linux-${ARCH}" \
    && curl -fsSL -o /usr/local/bin/forgejo-runner "${FORGEJO_URL}" \
    && chmod +x /usr/local/bin/forgejo-runner \
    && chmod u+s /usr/bin/newuidmap /usr/bin/newgidmap \
    && forgejo-runner -v

RUN useradd --create-home --shell /bin/bash runner

WORKDIR /home/runner
RUN chown -R runner:runner /home/runner

USER runner

CMD ["forgejo-runner", "daemon", "-c", "/etc/forgejo-runner/config.yaml"]
