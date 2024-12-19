# Define paths and environment variables
WORK_NODE_DIR := work_node
COORDINATOR_DIR := coordinator

.PHONY: work_node_start work_node_vs-code work_node_clean work_node_stop work_node_backup_data work_node_edit_sops work_node_init_sops coordinator_start coordinator_clean

####################################################################################################
# Work Node

# Start mode 1: standalone Docker Compose
work_node_start: work_node_clean
	$(MAKE) -C $(WORK_NODE_DIR) start

# Start mode 2: for VS Code dev container
work_node_vs-code: work_node_clean
	$(MAKE) -C $(WORK_NODE_DIR) vs-code

# Clean up ephemeral files
work_node_clean:
	$(MAKE) -C $(WORK_NODE_DIR) clean

# Stop the environment
work_node_stop:
	$(MAKE) -C $(WORK_NODE_DIR) stop

# Backup the database
work_node_backup_data:
	$(MAKE) -C $(WORK_NODE_DIR) backup_data

# Edit SOPS secrets
work_node_edit_sops:
	$(MAKE) -C $(WORK_NODE_DIR) edit_sops

# Initialize SOPS configuration
work_node_init_sops:
	$(MAKE) -C $(WORK_NODE_DIR) init_sops

####################################################################################################
# Coordinator

# Start the Phoenix server in the coordinator
coordinator_start:
	$(MAKE) -C $(COORDINATOR_DIR) start

# Start the Phoenix server in the coordinator with IEx
coordinator_start_iex:
	$(MAKE) -C $(COORDINATOR_DIR) start_iex

# Clean up compiled files in the coordinator
coordinator_clean:
	$(MAKE) -C $(COORDINATOR_DIR) clean