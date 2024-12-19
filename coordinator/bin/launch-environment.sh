#!/bin/bash
set -euo pipefail

# Path to the SOPS-encrypted secrets file
SECRETS_FILE="config/secrets.enc.json"

# Ensure sops and gpg are available
command -v sops >/dev/null 2>&1 || { echo "sops not found, please install sops."; exit 1; }
command -v gpg >/dev/null 2>&1 || { echo "gpg not found, please install gpg."; exit 1; }

# Warm up the gpg-agent by encrypting and decrypting a test string using the key in the SOPS file
if [ -f "$SECRETS_FILE" ]; then
    FINGERPRINT=$(jq -r '.sops.pgp[0].fp' "$SECRETS_FILE" 2>/dev/null || true)
    if [ -n "$FINGERPRINT" ] && [ "$FINGERPRINT" != "null" ]; then
        echo "Unlocking GPG agent with fingerprint $FINGERPRINT"
        echo "Unlock me plz" | gpg --encrypt --recipient "$FINGERPRINT" | gpg --decrypt > /dev/null 2>&1 || {
            echo "Failed to warm up gpg-agent. Check your GPG setup."
            exit 1
        }
    fi
else
    echo "Secrets file $SECRETS_FILE not found."
    exit 1
fi

export GPG_TTY=$(tty)

# # Decrypt the secrets into a JSON string in memory
# echo "Decrypting SOPS secrets..."
# decrypted_content=$(sops --input-type json --output-type json --decrypt "$SECRETS_FILE")

# # Convert JSON to environment variables
# # Assumes keys are uppercase and values are strings
# while IFS="=" read -r key value; do
#     # If your JSON keys are uppercase strings and values are simple strings,
#     # the following jq command will produce lines like KEY=VALUE.
#     # Adjust as needed if your structure differs.
#     export "$key"="$value"
# done < <(echo "$decrypted_content" | jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]')

# Determine how to launch the coordinator
MODE="${1:-mix}"

case "$MODE" in
    iex)
        echo "Starting coordinator in IEx mode..."
        exec sops exec-env "$SECRETS_FILE" "iex -S mix phx.server"
        ;;
    *)
        echo "Starting coordinator in Mix mode..."
        exec sops exec-env "$SECRETS_FILE" "mix phx.server"
        ;;
esac
