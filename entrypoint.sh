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
        echo -e "RECOVER_AUTOMATICALLY=1 so attempting to automatically recover by dropping state_compressor_progress, state_compressor_state, and state_compressor_total_progress tables."
        # Drop specified tables using the local psql command
        psql -d "$POSTGRES_LOCATION" -c "DROP TABLE state_compressor_progress; DROP TABLE state_compressor_state; DROP TABLE state_compressor_total_progress;"
    else
        echo "The compressor encountered an error, check the logs above for more details."
        echo "If recovery is needed, consider dropping the tables state_compressor_progress, state_compressor_state, and state_compressor_total_progress in the Synapse database, which you can do automatically by setting RECOVER_AUTOMATICALLY=1 in this container's environment variables."
    fi
fi

# Check for exit code 137
if [ "$exit_code" -eq 137 ]; then
    # Output a message indicating the compressor was terminated by the system, possibly due to memory constraints
    echo "The compressor was terminated by the system, likely due to reaching memory limits."
    echo "Check your configured limits in Docker in case they are too restrictive, otherwise consider lowering the CHUNK_SIZE or CHUNKS_TO_COMPRESS limits."
fi

# Exit with the original exit code
exit $exit_code
