defmodule BitTorrent.Peer.Controller do
  alias BitTorrent.Peer.Controller
  alias BitTorrent.Peer.Utils

  use GenServer

  defstruct torrents: [], peers: %{}

  require Logger

  @interval 10000

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

  def handle_call({:get_peers, info_hash, announce_url}, _from, state) do
    state = %{state | torrent: Utils.insert_torrent(state.torrent, {info_hash, announce_url})}
    peers = case Map.get(state.peers, info_hash) do
      nil ->
        Task.Supervisor.async(BitTorrent.TaskSupervisor, fn ->
          BitTorrent.Peer.Request.send({info_hash, announce_url})
        end) |> Task.await
      value ->
        value
    end
    {:reply, peers, %{state | peers: Map.put(state.peers, info_hash, peers)}}
  end

  def handle_info({ref, result}, state) do
    peers_map = case result do
      {:error, reason} ->
        Logger.info("Error in receiving peers: #{reason}")
        state.peers
      {:ok, {info_hash, peers}} ->
        Map.put(state.peers, info_hash, peers)
    end
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
      BitTorrent.Peer.Request.send(head)
    end)
    keep_alive(tail)
  end

  defp schedule_interval() do
    Logger.info("Scheduling interval")
    Process.send_after(__MODULE__, :keep_alive, @interval)
  end
end
