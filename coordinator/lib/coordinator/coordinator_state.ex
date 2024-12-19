defmodule Coordinator.CoordinatorState do
  use GenServer

  @lock_ttl :timer.minutes(30)

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    state = Map.merge(state, %{
      nodes: %{}, # node_id => %{info: map(), last_seen: DateTime}
      locks: %{}  # {job_name, interval_id} => %{locked_by: node_id, locked_at: DateTime}
    })
    {:ok, state}
  end

  def register_node(node_id, info) do
    GenServer.call(__MODULE__, {:register_node, node_id, info})
  end

  def unregister_node(node_id) do
    GenServer.call(__MODULE__, {:unregister_node, node_id})
  end

  def acquire_lock(job_name, interval_id, node_id) do
    GenServer.call(__MODULE__, {:acquire_lock, job_name, interval_id, node_id})
  end

  def release_lock(job_name, interval_id, node_id) do
    GenServer.call(__MODULE__, {:release_lock, job_name, interval_id, node_id})
  end

  @impl true
  def handle_call({:register_node, node_id, info}, _from, state) do
    now = DateTime.utc_now()
    state = put_in(state[:nodes][node_id], %{info: info, last_seen: now})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:unregister_node, node_id}, _from, state) do
    state = update_in(state[:nodes], &Map.delete(&1, node_id))
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:acquire_lock, job_name, interval_id, node_id}, _from, state) do
    key = {job_name, interval_id}
    case Map.get(state.locks, key) do
      nil ->
        # lock is free
        new_lock = %{locked_by: node_id, locked_at: DateTime.utc_now()}
        Process.send_after(self(), {:expire_lock, key}, @lock_ttl)
        state = put_in(state[:locks][key], new_lock)
        {:reply, {:ok, new_lock}, state}
      %{locked_by: ^node_id} = lock ->
        # Already locked by same node
        {:reply, {:ok, lock}, state}
      _other ->
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:release_lock, job_name, interval_id, node_id}, _from, state) do
    key = {job_name, interval_id}
    case Map.get(state.locks, key) do
      %{locked_by: ^node_id} ->
        state = update_in(state[:locks], &Map.delete(&1, key))
        {:reply, :ok, state}
      _ ->
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_info({:expire_lock, key}, state) do
    # lock expired
    state = update_in(state[:locks], &Map.delete(&1, key))
    {:noreply, state}
  end
end
