#!/bin/sh

# Check if POSTGRES_PATH is provided
if [ -z "$POSTGRES_PATH" ]; then
    POSTGRES_LOCATION="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB"
else
    POSTGRES_LOCATION="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@/$POSTGRES_DB?host=$POSTGRES_PATH"
fi

# Run the tool with the constructed connection string and other environment variables
/usr/local/bin/synapse_auto_compressor -p "$POSTGRES_LOCATION" -c "$CHUNK_SIZE" -n "$CHUNKS_TO_COMPRESS" -l "$COMPRESSION_LEVELS"

# Capture the exit code
exit_code=$?

# Check for exit code 0
if [ "$exit_code" -eq 0 ]; then
    # Output a message indicating the compressor exited normally
    echo "The compressor has exited normally."
fi

# Check for exit code 101 and RECOVER_AUTOMATICALLY flag
if [ "$exit_code" -eq 101 ]; then
    if [ "$RECOVER_AUTOMATICALLY" -eq 1 ]; then
        echo -e "RECOVER_AUTOMATICALLY is set to 1, so attempting to automatically drop state_compressor_progress, state_compressor_state, and state_compressor_total_progress tables."
        # Drop specified tables using the local psql command
        PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -c "DROP TABLE state_compressor_progress; DROP TABLE state_compressor_state; DROP TABLE state_compressor_total_progress;"
    else
        echo "The compressor is unable to continue, possibly because the room it was last working on has been purged."
        echo "It's recommended to DROP the tables state_compressor_progress, state_compressor_state, and state_compressor_total_progress in the Synapse database to continue."
    fi
fi

# Check for exit code 137
if [ "$exit_code" -eq 137 ]; then
    # Output a message indicating the compressor reached its limit
    echo "The compressor has reached its limit of chunks to compress and has ended. It will need to be started again to resume."
fi

# Exit with the original exit code
exit $exit_code
