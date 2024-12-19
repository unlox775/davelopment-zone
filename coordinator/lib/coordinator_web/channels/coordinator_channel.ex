defmodule CoordinatorWeb.CoordinatorChannel do
  use Phoenix.Channel
  alias Coordinator.CoordinatorState

  @impl true
  def join("coordinator:main", %{"node_id" => node_id, "info" => info}, socket) do
    :ok = CoordinatorState.register_node(node_id, info)
    {:ok, assign(socket, :node_id, node_id)}
  end

  @impl true
  def handle_in("acquire_lock", %{"job_name" => job_name, "interval_id" => interval_id}, socket) do
    node_id = socket.assigns.node_id
    case CoordinatorState.acquire_lock(job_name, interval_id, node_id) do
      {:ok, _lock} ->
        push(socket, "lock_acquired", %{"job_name" => job_name, "interval_id" => interval_id})
      :error ->
        push(socket, "lock_denied", %{"job_name" => job_name, "interval_id" => interval_id})
    end
    {:noreply, socket}
  end

  @impl true
  def handle_in("release_lock", %{"job_name" => job_name, "interval_id" => interval_id}, socket) do
    node_id = socket.assigns.node_id
    case CoordinatorState.release_lock(job_name, interval_id, node_id) do
      :ok -> push(socket, "lock_released", %{"job_name" => job_name, "interval_id" => interval_id})
      :error -> push(socket, "lock_release_error", %{"job_name" => job_name, "interval_id" => interval_id})
    end
    {:noreply, socket}
  end

  def handle_in("request_logs", %{"requestor" => req_id, "source" => src_id, "from_version" => fv, "to_version" => tv}, socket) do
    # forward to source node
    broadcast_from!(socket, "send_logs", %{"requestor" => req_id, "from_version" => fv, "to_version" => tv, "source" => src_id})
    {:noreply, socket}
  end

  def handle_in("send_logs", %{"requestor" => req_id, "logs" => logs, "source" => src_id}, socket) do
    # forward logs batch to requestor
    broadcast_from!(socket, "logs_batch", %{"requestor" => req_id, "logs" => logs, "source" => src_id})
    {:noreply, socket}
  end

  def handle_in("log_update", %{"node_id" => n_id, "version" => v, "log_entry" => entry}, socket) do
    broadcast_from!(socket, "log_update", %{"node_id" => n_id, "version" => v, "log_entry" => entry})
    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    if node_id = socket.assigns[:node_id] do
      CoordinatorState.unregister_node(node_id)
    end
    :ok
  end
end
