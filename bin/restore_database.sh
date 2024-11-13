#!/bin/bash

SECRETS_FILE=/tmp/local_ephemeral_vault/secrets.json
DATA_BACKUP_KEY=$(jq -r '.data_backup_key' "$SECRETS_FILE" | base64 -d)

# Ensure we have a valid key
if [ -z "$DATA_BACKUP_KEY" ]; then
  echo "Error: Data backup key not found in secrets file. Exiting."
  exit 1
fi

# Define backup paths
RESTORE_DIR=$(mktemp -d)
BACKUP_DIR="/workspace/data_backup"
MANIFEST_FILE="$BACKUP_DIR/manifest.json"
RESTORE_FILE="$RESTORE_DIR/db_restore.sql"

# Check if the database exists
DB_EXISTS=$(psql -h db -U postgres -lqt | cut -d \| -f 1 | grep -w davelopment_zone | wc -l)

if [ "$DB_EXISTS" -eq 1 ]; then
  echo "Error: Database 'davelopment_zone' already exists. Exiting."
  exit 1
fi

# Decrypt each chunk using the key
for chunk in $(jq -r '.chunks[]' "$MANIFEST_FILE"); do
  echo "Decrypting $chunk ..." 
  echo "$DATA_BACKUP_KEY" | openssl enc -d -aes-256-cbc -salt -pbkdf2 -iter 100000 -in "$chunk" -out "$RESTORE_DIR/$(basename "$chunk" .enc)" -pass stdin || exit 1
done

# Combine the decrypted chunks into a single SQL file
cat "$RESTORE_DIR"/db_backup_chunk_* > "$RESTORE_FILE"

# Restore the database
echo "Creating database 'davelopment_zone' ..."
psql -h db -U postgres -d postgres -c "CREATE DATABASE davelopment_zone" || exit 1

echo "Restoring database from $RESTORE_FILE ..."
psql -h db -U postgres -d davelopment_zone -f "$RESTORE_FILE"

# Clean up decrypted chunks and restore file
#rm "$RESTORE_DIR"/db_backup_chunk_*
#rm "$RESTORE_FILE"

echo "Database restoration completed from $RESTORE_DIR"