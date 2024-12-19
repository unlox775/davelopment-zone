# Define paths and environment variables
MIX_ENV := dev

.PHONY: start clean

# Start the Phoenix server
start:
	MIX_ENV=$(MIX_ENV) mix phx.server

start_iex:
	MIX_ENV=$(MIX_ENV) iex -S mix phx.server

# Clean up compiled files
clean:
	MIX_ENV=$(MIX_ENV) mix clean