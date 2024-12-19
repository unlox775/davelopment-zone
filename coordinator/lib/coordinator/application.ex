defmodule Coordinator.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      CoordinatorWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:coordinator, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Coordinator.PubSub},
      {Finch, name: Coordinator.Finch},
      CoordinatorWeb.Endpoint,
      {Coordinator.CoordinatorState, []},
      {Coordinator.NgrokPortHandler, []}
    ]

    opts = [strategy: :one_for_one, name: Coordinator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    CoordinatorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
