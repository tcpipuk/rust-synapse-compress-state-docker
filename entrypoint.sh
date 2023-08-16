#!/bin/sh

# Check if POSTGRES_PATH is provided
if [ -z "$POSTGRES_PATH" ]; then
    CONNECTION_STRING="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB"
else
    CONNECTION_STRING="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@/$POSTGRES_DB?host=$POSTGRES_PATH"
fi

# Run the tool with the constructed connection string and other environment variables
exec /usr/local/bin/synapse_auto_compressor -p "$CONNECTION_STRING" -c "$CHUNK_SIZE" -n "$MIN_STATE_GROUP" -l "$COMPRESSION_LEVELS"
