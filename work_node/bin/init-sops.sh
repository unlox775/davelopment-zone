#!/bin/bash

# Define paths and environment variables
SECRETS_FILES="config/secrets.enc.json"

# Extract all keys except the 'sops' attribute
keys=$(cat $SECRETS_FILES | jq 'del(.sops) | keys')

# Create a new JSON object with the extracted keys and dummy values
new_content=$(echo "$keys" | jq 'reduce .[] as $key ({}; .[$key] = "dummy_value")')

# Write the new content to the secrets file
echo "$new_content" > "$SECRETS_FILES"

# Generate a new GPG key interactively
gpg --full-generate-key

# Get the new GPG key fingerprint
NEW_GPG_FINGERPRINT=$(gpg --list-keys --with-colons | grep '^fpr' | head -n 1 | cut -d: -f10)

# Export the GPG key to the public keyring
gpg --export > ~/.gnupg/pubring.gpg

# Configure GPG agent to allow loopback pinentry
echo "allow-loopback-pinentry" >> ~/.gnupg/gpg-agent.conf
gpgconf --kill all
gpgconf --launch gpg-agent

# Output the new GPG key fingerprint
echo "New GPG Key Fingerprint: $NEW_GPG_FINGERPRINT"

# Update the SOPS configuration file with the new GPG key fingerprint
if [ -f .sops.yaml ]; then
    # Update the existing pgp key
    sed -i '' "s/pgp: .*/pgp: $NEW_GPG_FINGERPRINT/" .sops.yaml
else
    # Create the SOPS configuration file if it doesn't exist
    keys_regex=$(echo "$keys" | jq -r 'join("|")')
    cat <<EOF > .sops.yaml
creation_rules:
    - encrypted_regex: '^($keys_regex)$'
        pgp: $NEW_GPG_FINGERPRINT
EOF
fi

# Encrypt the secrets file using SOPS
sops --encrypt --in-place $SECRETS_FILES

echo "SOPS initialization complete."
