ARG ELIXIR_VERSION=1.18.1
ARG ERLANG_VERSION=27.2
ARG ALPINE_VERSION=3.21.2

ARG BUILD_ELIXIR_IMAGE=hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION}
ARG RUNTIME_IMAGE=alpine:${ALPINE_VERSION}

# ---- Build Stage ----
FROM ${BUILD_ELIXIR_IMAGE} as app_builder

# Set environment variables for building the application
ENV MIX_ENV=prod \
    TEST=1 \
    LANG=C.UTF-8

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install dependencies required to compile deps
RUN apk add --update build-base npm

# Create the application build directory
RUN mkdir /app
WORKDIR /app

# Copy over all the necessary application files and directories
COPY apps ./apps
COPY config ./config
COPY mix.exs .
COPY mix.lock .

# Fetch the application dependencies and build the application
RUN mix deps.get
RUN mix deps.compile
RUN mix assets.deploy
RUN mix release

# ---- Application Stage ----
FROM ${RUNTIME_IMAGE} AS app

ENV LANG=C.UTF-8

# Install openssl
RUN apk update && \
    apk add openssl ncurses-libs libstdc++ libgcc

# Copy over the build artifact from the previous step and create a non root user
RUN adduser -D app
WORKDIR /home/app
COPY --from=app_builder /app/_build .
RUN chown -R app: ./prod

# Copy the start script
ADD scripts/start_commands.sh /scripts/start_commands.sh
RUN chown app: /scripts/start_commands.sh && \
    chmod +x /scripts/start_commands.sh

USER app

# run the start-up script which run migrations and then the app
ENTRYPOINT ["/scripts/start_commands.sh"]
