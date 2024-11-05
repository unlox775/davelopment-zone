#!/bin/sh

# Verify the ephemeral RSA private key is available
if [ -z "$EPHEMERAL_RSA_KEY" ]; then
  echo "Ephemeral RSA private key not set. Exiting."
  exit 1
fi

# Loop through all files in the ephemeral vault, decrypt, and load into runtime
mkdir -p /tmp/local_ephemeral_vault
for enc_file in /ephemeral_vault/*; do
    decrypted_content=$(openssl rsautl -decrypt -inkey <(echo "$EPHEMERAL_RSA_KEY") -in "$enc_file")
    echo "$decrypted_content" > "/tmp/local_ephemeral_vault/$(basename "$enc_file" .enc.json).json"
done

exec "$@"