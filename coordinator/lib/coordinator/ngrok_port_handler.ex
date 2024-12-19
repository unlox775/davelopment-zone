defmodule Coordinator.NgrokPortHandler do
  use GenServer
  require Logger

  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    port_cmd = System.find_executable("ngrok")
    args = ["http", "4000", "--log=stdout", "--log-format=json"]
    Port.open({:spawn_executable, port_cmd}, [:binary, :exit_status, {:args, args}])
    {:ok, %{}}
  end

  @impl true
  def handle_info({port, {:data, line}}, state) when is_port(port) do
    msg = String.trim(line)
    Logger.info("ngrok: #{msg}")

    case Jason.decode(msg) do
      {:ok, %{"msg" => "started tunnel", "url" => url}} ->
        print_instructions(url)
      _ ->
        :ok
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({port, {:exit_status, code}}, state) when is_port(port) do
    Logger.error("ngrok exited with status: #{code}")
    {:noreply, state}
  end

  defp print_instructions(url) do
    IO.puts("""
    ============================================
    NGROK TUNNEL CREATED
    ============================================
    URL: #{url}
    ============================================
    Please pass this URL to the children.
    ============================================
    """)
  end
end
