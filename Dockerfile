# Builder stage
FROM rust:alpine AS builder

# Install build dependencies
RUN apk add --no-cache git make musl-dev openssl-dev python3 pkgconfig

# Clone the repository
RUN git clone https://github.com/matrix-org/rust-synapse-compress-state.git /opt/synapse-compressor/
WORKDIR /opt/synapse-compressor/

# Build the project
ENV RUSTFLAGS="-C target-feature=-crt-static"

# arm64 builds consume a lot of memory if `CARGO_NET_GIT_FETCH_WITH_CLI` is not
# set to true, so we expose it as a build-arg.
ARG CARGO_NET_GIT_FETCH_WITH_CLI=false
ENV CARGO_NET_GIT_FETCH_WITH_CLI=$CARGO_NET_GIT_FETCH_WITH_CLI

RUN cargo build --release
WORKDIR /opt/synapse-compressor/synapse_auto_compressor/
RUN cargo build --release
RUN find /opt/synapse-compressor/target/ -type f -name "synapse*"

# Live image stage
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache libgcc

# Copy binaries from the builder stage
COPY --from=builder /opt/synapse-compressor/target/*/synapse_compress_state /usr/local/bin/synapse_compress_state
COPY --from=builder /opt/synapse-compressor/target/*/synapse_auto_compressor /usr/local/bin/synapse_auto_compressor

# Set default environment variables for the command arguments and Postgres details
ENV POSTGRES_USER="synapse" \
    POSTGRES_PASSWORD="password" \
    POSTGRES_HOST="127.0.0.1" \
    POSTGRES_PORT="5432" \
    POSTGRES_DB="synapse" \
    POSTGRES_PATH="" \
    CHUNK_SIZE="500" \
    CHUNKS_TO_COMPRESS="100" \
    COMPRESSION_LEVELS="100,50,25"

# Script to determine the connection string based on environment variables
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
