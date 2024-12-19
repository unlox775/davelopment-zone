defmodule DavelopmentZone.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DavelopmentZoneWeb.Telemetry,
      DavelopmentZone.Repo,
      {DNSCluster, query: Application.get_env(:davelopment_zone, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DavelopmentZone.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: DavelopmentZone.Finch},
      # Start a worker by calling: DavelopmentZone.Worker.start_link(arg)
      # {DavelopmentZone.Worker, arg},
      # Start to serve requests, typically the last entry
      DavelopmentZoneWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DavelopmentZone.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DavelopmentZoneWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
