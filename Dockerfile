# First stage: Caddy setup
FROM caddy:latest AS caddy
COPY Caddyfile ./
RUN caddy fmt --overwrite Caddyfile


FROM golang:1.21 AS builder
WORKDIR /app

# Clone your repository
ARG REPO_URL="https://github.com/kelldw/listmonk"
ARG BRANCH="master"
RUN git clone -b ${BRANCH} ${REPO_URL} .



# Build listmonk
RUN make build-deps
RUN make build


# Install dependencies and build
# Adjust these commands based on your application:
RUN npm install
RUN npm run build


# Final stage: Runtime
FROM debian:bullseye-slim
WORKDIR /app

# Copy built application from builder stage
COPY --from=builder /app/listmonk ./
COPY --from=builder /app/config.toml.sample ./config.toml
COPY --from=builder /app/static ./static
COPY --from=builder /app/i18n ./i18n

# Copy Caddy configurations
COPY --from=caddy /srv/Caddyfile ./
COPY --from=caddy /usr/bin/caddy /usr/bin/caddy

# Add runtime dependencies
RUN apt-get update && apt-get install -y \
    parallel \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Copy scripts
COPY --chmod=755 scripts/* ./

# Set environment variables
ENV PORT=9000

ENTRYPOINT ["/bin/sh"]
CMD ["start.sh"]
