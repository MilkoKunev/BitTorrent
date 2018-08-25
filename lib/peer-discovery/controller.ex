defmodule BitTorrent.Discovery.Controller do
  alias BitTorrent.Discovery.Controller
  alias BitTorrent.Discovery.Utils

  use GenServer

  defstruct torrents: [], peers: %{}

  require Logger

  @interval 1000000

  # API
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_peers(info_hash, announce_url) do
    GenServer.call(__MODULE__, {:get_peers, info_hash, announce_url})
  end

# CALLBACKS
  def init(_args) do
    state = %Controller{}
    schedule_interval()
    {:ok, state}
  end

  def handle_call({:get_peers, info_hash, announce_url}, from, state) do
    state = %{state | torrents: Utils.insert_torrent(state.torrents, {info_hash, announce_url})}
    case Map.get(state.peers, info_hash) do
      nil ->
        Task.Supervisor.async_nolink(BitTorrent.TaskSupervisor, fn ->
            result = BitTorrent.Discovery.Request.send({info_hash, announce_url})
            {:received_peers, from, result}
        end)
        {:noreply, state}
      peers ->
        {:reply, peers, %{state | peers: Map.put(state.peers, info_hash, peers)}}
    end
  end

  def handle_info({_ref, {:received_peers, from, result}}, state) do
    case result do
      {:error, _reason} ->
        GenServer.reply(from, nil)
        {:noreply, state}
      {:ok, {info_hash, peers}} ->
        GenServer.reply(from, peers)
        {:noreply, %{state | peers: Map.put(state.peers, info_hash, peers)}}
    end
  end

  def handle_info({_ref, {:keeping_conn_alive, result}}, state) do
    peer_map = case result do
      {:error, reason} ->
        Logger.info("Error in receiving peers: #{reason}")
        state.peers
      {:ok, {info_hash, peers}} ->
        Map.put(state.peers, info_hash, peers)
    end
    {:noreply, %{state | peers: peer_map}}
  end

  def handle_info({:DOWN, _, _, _, _}, state) do
    {:noreply, state}
  end

  def handle_info(:keep_alive, state) do
    keep_alive(state.torrents)
    schedule_interval()
    {:noreply, state}
  end

  # Helper functions
  defp keep_alive([]) do
    []
  end

  defp keep_alive([head | tail]) do
    Task.Supervisor.async_nolink(BitTorrent.TaskSupervisor, fn ->
      result = BitTorrent.Discovery.Request.send(head)
      {:keeping_conn_alive, result}
    end)
    keep_alive(tail)
  end

  defp schedule_interval() do
    Logger.info("Scheduling interval")
    Process.send_after(__MODULE__, :keep_alive, @interval)
  end
end
