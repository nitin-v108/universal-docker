# Node.js container with NVM – multiple Node versions (24, 20, 18, etc.)
# Credit Control and other Node APIs; PM2 to run them.
# Windows 11 + WSL2 Docker local dev

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Development tools (bash required for NVM and CMD)
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    git \
    build-essential \
    curl \
    ca-certificates \
    apt-transport-https \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# NVM (Node Version Manager) – install and use Node 24 by default
ENV NVM_DIR=/root/.nvm
ENV NODE_VERSION_DEFAULT=24

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install 24 \
    && nvm alias default 24 \
    && npm install -g pm2

# Ensure bash loads NVM in interactive and non-interactive shells
RUN echo "export NVM_DIR=\"$NVM_DIR\"" >> /root/.bashrc \
    && echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"" >> /root/.bashrc

WORKDIR /var/www

# Start with NVM loaded, Node 24, then run Credit Control API
CMD ["bash", "-c", ". $NVM_DIR/nvm.sh && nvm use 24 && cd /var/www/credit-control && npm install && npm run build:dev && exec pm2 start ecosystem.config.cjs --env development --no-daemon"]
