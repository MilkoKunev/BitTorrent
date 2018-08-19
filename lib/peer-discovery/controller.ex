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

  def handle_call({:get_peers, info_hash, announce_url}, _from, state) do
    state = %{state | torrents: Utils.insert_torrent(state.torrents, {info_hash, announce_url})}
    peers = case Map.get(state.peers, info_hash) do
      nil ->
        {:ok, {_info_hash, peers}} = Task.Supervisor.async(BitTorrent.TaskSupervisor, fn ->
                                BitTorrent.Discovery.Request.send({info_hash, announce_url})
                              end)
                              |> Task.await
        peers
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
      BitTorrent.Discovery.Request.send(head)
    end)
    keep_alive(tail)
  end

  defp schedule_interval() do
    Logger.info("Scheduling interval")
    Process.send_after(__MODULE__, :keep_alive, @interval)
  end
end