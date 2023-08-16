#!/bin/sh

# Check if POSTGRES_PATH is provided
if [ -z "$POSTGRES_PATH" ]; then
    POSTGRES_LOCATION="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB"
else
    POSTGRES_LOCATION="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@/$POSTGRES_DB?host=$POSTGRES_PATH"
fi

# Run the tool with the constructed connection string and other environment variables
exec /usr/local/bin/synapse_auto_compressor -p "$POSTGRES_LOCATION" -c "$CHUNK_SIZE" -n "$CHUNKS_TO_COMPRESS" -l "$COMPRESSION_LEVELS"
