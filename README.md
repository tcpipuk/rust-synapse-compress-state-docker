# Synapse State Compression Tool in Docker

This repository provides a Docker container for the
[rust-synapse-compress-state](https://github.com/matrix-org/rust-synapse-compress-state)
project developed by Matrix.org. The primary purpose is to offer a convenient way to run the
state compression tool for Synapse without dealing with manual installations and dependencies.

## How to Run

### Using Docker Run

**PostgreSQL with TCP port:**

```bash
docker pull ghcr.io/tcpipuk/rust-synapse-compress-state:latest
docker run -e POSTGRES_USER="synapse" -e POSTGRES_PASSWORD="YOUR_PASSWORD" -e POSTGRES_DB="synapse" -e POSTGRES_HOST="db" -e POSTGRES_PORT="5432" ghcr.io/tcpipuk/rust-synapse-compress-state:latest
```

**PostgreSQL with Unix sockets:**

```bash
docker pull ghcr.io/tcpipuk/rust-synapse-compress-state:latest
docker run -e POSTGRES_USER="synapse" -e POSTGRES_PASSWORD="YOUR_PASSWORD" -e POSTGRES_DB="db" -e POSTGRES_PATH="/path/to/socket/dir" ghcr.io/tcpipuk/rust-synapse-compress-state:latest
```

### Using docker-compose

**Example `docker-compose.yml` for PostgreSQL with TCP port:**

```yaml
version: '3'

services:
  synapse-compress-state:
    image: ghcr.io/tcpipuk/rust-synapse-compress-state:latest
    environment:
      POSTGRES_USER: synapse
      POSTGRES_PASSWORD: YOUR_PASSWORD
      POSTGRES_DB: synapse
      POSTGRES_HOST: db
      POSTGRES_PORT: 5432
```

**Example `docker-compose.yml` for PostgreSQL with Unix sockets:**

```yaml
version: '3'

services:
  synapse-compress-state:
    image: ghcr.io/tcpipuk/rust-synapse-compress-state:latest
    environment:
      POSTGRES_USER: synapse
      POSTGRES_PASSWORD: YOUR_PASSWORD
      POSTGRES_DB: synapse
      POSTGRES_PATH: /path/to/socket/dir
```

## Optional Environment Variables

- `CHUNK_SIZE`: Determines the number of state groups to process at once. This is particularly
  useful for machines with limited memory as smaller chunk sizes can be set. If no space savings
  are found for the entire chunk, it's skipped. Default: "500".

- `CHUNKS_TO_COMPRESS`: Specifies the number of chunks (of size `CHUNK_SIZE`) to compress. The
  higher this value, the longer the compression process will run. Default: "100".

- `COMPRESSION_LEVELS`: Defines the sizes of each new level in the compression algorithm as a
  comma-separated list. The list's first entry is for the most granular level, with each subsequent
  entry for the next highest level. The total number of entries determines the algorithm's levels.
  The sum of the sizes impacts the state fetching performance from the database, as it sets the
  upper limit on the iterations needed to fetch a specific state set. Default: "100,50,25".

## Troubleshooting

### Understanding Exit Codes

The tool may exit with specific codes, indicating various states or issues:

- **Exit Code 0**: Normal exit. The compressor has completed its task without any errors.
- **Exit Code 101**: Indicates a Rust panic, often due to the room it was previously compressing
  being purged from the Synapse database. If `RECOVER_AUTOMATICALLY=1` is set, the tool will attempt
  to automatically recover by dropping the `state_compressor_progress`, `state_compressor_state`,
  and `state_compressor_total_progress` tables.
- **Exit Code 137**: This typically indicates that the compressor was terminated by the system,
  likely due to reaching memory limits. The defaults can consume over 1GB of memory on a large room,
  so consider checking your Docker configured limits and possibly lowering the `CHUNK_SIZE` or
  `CHUNKS_TO_COMPRESS` values.

### Automatic Recovery

Setting `RECOVER_AUTOMATICALLY=1` in environment variables enables the tool to automatically drop
the `state_compressor_progress`, `state_compressor_state`, and `state_compressor_total_progress`
tables and start from scratch when critical failures (error code 101) occur. While this can resolve
common issues, such as a room being purged from the Synapse database, it should be used with caution
as it involves modifying the database schema - users enable this feature at their own risk.
