# Builder stage
FROM rust:alpine as builder

# Install build dependencies
RUN apk add --no-cache build-base git

# Clone the repository
RUN git clone https://github.com/matrix-org/rust-synapse-compress-state.git /rust-synapse-compress-state
WORKDIR /rust-synapse-compress-state

# Build the project
RUN cargo build --release

# Live image stage
FROM alpine:latest

# Copy the built binary from the builder stage
COPY --from=builder /rust-synapse-compress-state/target/release/synapse_auto_compressor /usr/local/bin/

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
