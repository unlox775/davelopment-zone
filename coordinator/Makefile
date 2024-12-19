# Define paths and environment variables
MIX_ENV := dev
SECRETS_FILES := config/secrets.enc.json
EPHEMERAL_VAULT := /tmp/coordinator_ephemeral_vault
SOPS_CONFIG := .sops.yaml

.PHONY: start start_iex clean edit_sops init_sops sops sops_edit

# Start the Phoenix server using the launch-environment script
start:
	MIX_ENV=$(MIX_ENV) bin/launch-environment.sh mix

# Start the Phoenix server in IEx mode using the launch-environment script
start_iex:
	MIX_ENV=$(MIX_ENV) bin/launch-environment.sh iex

# Clean up compiled files
clean:
	MIX_ENV=$(MIX_ENV) mix clean

# Edit SOPS secrets
edit_sops:
	@if [ ! -d "/workspace" ] && [ "$(uname)" != "Linux" ]; then \
		FINGERPRINT=$$(jq -r '.sops.pgp[0].fp' $(SECRETS_FILES)); \
		ENCRYPTED_REGEX=$$(yq e '.creation_rules[0].encrypted_regex' $(SOPS_CONFIG)); \
		echo "Unlocking GPG agent with fingerprint $$FINGERPRINT"; \
		echo "Unlock me plz" | gpg --encrypt --recipient "$$FINGERPRINT" | gpg --decrypt > /dev/null 2>&1; \
		export GPG_TTY=$(tty); \
		sops --encrypted-regex "$$ENCRYPTED_REGEX" $(SECRETS_FILES); \
	else \
		echo "Error: This command must be run outside of a Docker container"; \
		exit 1; \
	fi

# Initialize SOPS configuration
init_sops:
	bin/init-sops.sh

# Aliases for editing SOPS secrets
sops: edit_sops
sops_edit: edit_sops