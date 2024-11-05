# Define paths and environment variables
REPO_NAME := $(shell basename $(shell pwd))
EPHEMERAL_VAULT := /tmp/$(REPO_NAME)_ephemeral_vault
SECRETS_FILES := config/secrets.enc.json

.PHONY: start vs-code clean

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