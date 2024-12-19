#!/bin/bash

# Ensure EPHEMERAL_VAULT is set
if [ -z "$EPHEMERAL_VAULT" ]; then
  echo "Error: EPHEMERAL_VAULT is not set. Exiting."
  exit 1
fi

# Mode check
if [ -z "$1" ]; then
  echo "Error: No mode specified. Use 'docker' or 'vscode'."
  exit 1
fi

MODE=$1
SECRETS_FILES=("config/secrets.enc.json")  # Extendable to other secret files

# Check, ephemeral vault must NOT exist
if [ -d "$EPHEMERAL_VAULT" ]; then
  echo "Error: Ephemeral vault already exists at $EPHEMERAL_VAULT. Exiting."
  exit 1
fi

echo "Creating ephemeral vault at $EPHEMERAL_VAULT"
mkdir -p "$EPHEMERAL_VAULT"

# Generate ephemeral RSA key pair for in-memory re-encryption
echo "Generating in-memory RSA key pair for re-encryption..."
ephemeral_pub_key_file=$(mktemp)
EPHEMERAL_RSA_PRIVATE=$(openssl genpkey -algorithm RSA -outform PEM -pkeyopt rsa_keygen_bits:2048)
echo "$EPHEMERAL_RSA_PRIVATE" | openssl rsa -pubout -outform PEM > $ephemeral_pub_key_file

echo -n "Encrypting secrets using temp RSA key: "
echo "$EPHEMERAL_RSA_PRIVATE" | openssl pkey -pubout 2>/dev/null | openssl dgst -sha256 | awk '{print $2}'

# Unlock gpg-agent (SOPS can't ask for passphrase in non-interactive mode)
FINGERPRINT=$(jq -r '.sops.pgp[0].fp' config/secrets.enc.json)
echo "Unlocking GPG agent with fingerprint $FINGERPRINT"
echo "Unlock me plz" | gpg --encrypt --recipient "$FINGERPRINT" | gpg --decrypt > /dev/null 2>&1
export GPG_TTY=$(tty)

# Decrypt SOPS files and re-encrypt with the ephemeral RSA public key
for file in "${SECRETS_FILES[@]}"; do
  echo "Decrypting $file with SOPS and re-encrypting with RSA..."
  decrypted_content=$(sops --input-type json --output-type json --decrypt "$file")
  echo "length of decrypted content: ${#decrypted_content}"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to decrypt $file with SOPS. Exiting."
    exit 1
  fi
  echo "$decrypted_content" | openssl pkeyutl -encrypt -pubin -inkey "$ephemeral_pub_key_file" > "$EPHEMERAL_VAULT/$(basename "$file")"
done

# Cleanup temporary public key file
rm -f "$ephemeral_pub_key_file"

# Export the ephemeral private key to environment variable for container access
export EPHEMERAL_KEY="$EPHEMERAL_RSA_PRIVATE"

# Define the workspace path, the parent directory of the current script
WORKSPACE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Start the chosen environment
if [ "$MODE" == "docker" ]; then
  cd "$WORKSPACE_PATH/../.devcontainer"
  echo "Just in case: docker-compose down"
  docker-compose down
  
  echo "Starting Docker Compose with ephemeral key"
  EPHEMERAL_VAULT="$EPHEMERAL_VAULT" docker-compose up -d
elif [ "$MODE" == "vscode" ]; then
  echo "Just in case: devcontainer down"
  devcontainer down # not yet impmlemented, but planned

  echo "Starting VS Code dev container with ephemeral key"
  devcontainer up --workspace-folder "$WORKSPACE_PATH/.." --remote-env "EPHEMERAL_VAULT=$EPHEMERAL_VAULT"
else
  echo "Error: Unknown mode '$MODE'. Use 'docker' or 'vscode'."
  exit 1
fi