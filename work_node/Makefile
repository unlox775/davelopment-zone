# Define paths and environment variables
REPO_NAME := $(shell basename $(shell pwd))
EPHEMERAL_VAULT := /tmp/$(REPO_NAME)_ephemeral_vault
SECRETS_FILES := config/secrets.enc.json

.PHONY: start vs-code clean stop backup_data edit_sops sops sops_edit init_sops

# Start mode 1: standalone Docker Compose
start: clean
	EPHEMERAL_VAULT=$(EPHEMERAL_VAULT) bin/launch-environment.sh docker

# Start mode 2: for VS Code dev container
vs-code: clean
	EPHEMERAL_VAULT=$(EPHEMERAL_VAULT) bin/launch-environment.sh vscode

# Clean up ephemeral files
clean:
	rm -rf $(EPHEMERAL_VAULT)
	# Verify cleanup
	[ ! -d $(EPHEMERAL_VAULT) ] && echo "Ephemeral vault cleaned up." || (echo "Failed to clean up ephemeral vault." && exit 1)

# Stop the environment
stop:
	cd .devcontainer; docker-compose down

# Backup the database
backup_data:
	@if [ -d "/workspace" ] && [ "$(uname)" = "Linux" ] && [ -f "/tmp/local_ephemeral_vault/secrets.json" ] && [ -s "/tmp/local_ephemeral_vault/secrets.json" ]; then \
		DATA_BACKUP_KEY=$$(jq -r '.DATA_BACKUP_KEY' /tmp/local_ephemeral_vault/secrets.json); \
		if [ -n "$$DATA_BACKUP_KEY" ]; then \
			/workspace/bin/backup-database.sh; \
		else \
			echo "Error: DATA_BACKUP_KEY is not set in /tmp/local_ephemeral_vault/secrets.json"; \
			exit 1; \
		fi \
	else \
		echo "Error: This command must be run inside a Docker container with the correct environment"; \
		exit 1; \
	fi

# Edit SOPS secrets
edit_sops:
	@if [ ! -d "/workspace" ] && [ "$(uname)" != "Linux" ]; then \
		FINGERPRINT=$$(jq -r '.sops.pgp[0].fp' $(SECRETS_FILES)); \
		echo "Unlocking GPG agent with fingerprint $$FINGERPRINT"; \
		echo "Unlock me plz" | gpg --encrypt --recipient "$$FINGERPRINT" | gpg --decrypt > /dev/null 2>&1; \
		export GPG_TTY=$(tty); \
		sops $(SECRETS_FILES); \
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