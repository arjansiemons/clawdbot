FROM node:22-bookworm

# Install dependencies for Homebrew
RUN apt-get update && \
    apt-get install -y -q --allow-unauthenticated \
    git \
    sudo \
    curl \
    procps \
    file \
    build-essential && \
    rm -rf /var/lib/apt/lists/*

# Create linuxbrew user and setup Homebrew
RUN useradd -m -s /bin/bash linuxbrew && \
    echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    mkdir -p /home/linuxbrew/.linuxbrew && \
    chown -R linuxbrew: /home/linuxbrew/.linuxbrew

USER linuxbrew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

USER root
RUN chown -R node: /home/linuxbrew/.linuxbrew
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
RUN git config --global --add safe.directory /home/linuxbrew/.linuxbrew/Homebrew

# Verify brew works as node user
USER node
RUN brew update && brew doctor || true

USER root
RUN corepack enable

WORKDIR /app

COPY --chown=node:node . .

USER node
RUN pnpm install --frozen-lockfile
RUN pnpm build
RUN pnpm ui:install
RUN pnpm ui:build

ENV NODE_ENV=production
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

CMD ["node", "dist/index.js"]
