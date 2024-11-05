# Use the official Elixir image, which includes both Elixir and Erlang, and supports multi-architecture
FROM elixir:1.14.2-alpine

# Install additional dependencies (e.g., SOPS, cron)
RUN apk update && \
    apk add --no-cache \
    bash \
    curl \
    git \
    inotify-tools \
    openssl \
    tzdata

# Install Phoenix dependencies
RUN mix local.hex --force && \
    mix archive.install hex phx_new --force

# Set the working directory
WORKDIR /workspace

# Expose the default Phoenix port
EXPOSE 4000

# Run the Phoenix server by default
CMD ["mix", "phx.server"]