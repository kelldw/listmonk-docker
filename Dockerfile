# First stage: Caddy setup
FROM caddy:latest AS caddy
COPY Caddyfile ./
RUN caddy fmt --overwrite Caddyfile

# Second stage: Build your application
# Replace 'node' with whatever base image matches your application:
# - python:3.11 for Python
# - golang:1.21 for Go
# - openjdk:17 for Java
# - ruby:3.2 for Ruby
FROM node:18 AS builder

WORKDIR /app

# Clone your repository
ARG REPO_URL="https://github.com/kelldw/listmonk.git"
ARG BRANCH="main"
RUN git clone -b ${BRANCH} ${REPO_URL} .

# Install dependencies and build
# Adjust these commands based on your application:
RUN npm install
RUN npm run build

# Final stage: Runtime
FROM node:18-slim

WORKDIR /app

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json .

# Copy Caddy configurations
COPY --from=caddy /srv/Caddyfile ./
COPY --from=caddy /usr/bin/caddy /usr/bin/caddy

# Add any additional runtime dependencies
RUN apt-get update && apt-get install -y \
    parallel \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Copy scripts
COPY --chmod=755 scripts/* ./

# Set any environment variables your app needs
ENV PORT=9000
ENV NODE_ENV=production

ENTRYPOINT ["/bin/sh"]
CMD ["start.sh"]
