#!/bin/bash

# these is not installed by default on the server under docker
apk add jq
apk add postgresql-client

SECRETS_FILE=/tmp/local_ephemeral_vault/secrets.json
DATA_BACKUP_KEY=$(jq -r '.data_backup_key' "$SECRETS_FILE")

# Ensure We have a valid key
if [ -z "$DATA_BACKUP_KEY" ]; then
  echo "Error: Data backup key not found in secrets file. Exiting."
  exit 1
fi

# Define backup paths
BACKUP_DIR="/workspace/data_backup"
BACKUP_FILE="$BACKUP_DIR/db_backup.sql"
CHUNK_SIZE=10485760  # 10 MB
MANIFEST_FILE="$BACKUP_DIR/manifest.json"
KEY_FILE="$EPHEMERAL_VAULT/data_backup_key"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Dump the Postgres database
pg_dump -h db -U postgres -d postgres -f "$BACKUP_FILE"

# Split the backup file into chunks
split -b $CHUNK_SIZE "$BACKUP_FILE" "$BACKUP_DIR/db_backup_chunk_"

# Encrypt each chunk using the key
for chunk in "$BACKUP_DIR"/db_backup_chunk_*; do
  openssl enc -aes-256-cbc -salt -in "$chunk" -out "$chunk.enc" -pass file:"$KEY_FILE"
  rm "$chunk"
done

# Generate manifest file
cat <<EOF > "$MANIFEST_FILE"
{
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "chunks": $(ls "$BACKUP_DIR"/*.enc | jq -R -s -c 'split("\n")[:-1]')
}
EOF

# Clean up unencrypted backup file
rm "$BACKUP_FILE"

echo "Database backup completed and encrypted in $BACKUP_DIR"