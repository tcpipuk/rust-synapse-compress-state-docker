# Builder stage
FROM rust:alpine AS builder

# Install build dependencies
RUN apk add --no-cache git make musl-dev openssl-dev python3 pkgconfig

# Clone the repository
RUN git clone https://github.com/matrix-org/rust-synapse-compress-state.git /opt/synapse-compressor/
WORKDIR /opt/synapse-compressor/

# Build the project
ENV RUSTFLAGS="-C target-feature=-crt-static"
RUN cargo build --release

# Live image stage
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache libgcc && find -type f /opt/synapse-compressor

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
