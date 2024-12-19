defmodule CoordinatorWeb.UserSocket do
  use Phoenix.Socket

  channel "coordinator:main", CoordinatorWeb.CoordinatorChannel

  # It’s probably by default JSON serializer. Just leave it as generated.
  # No authentication shown here.

  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
