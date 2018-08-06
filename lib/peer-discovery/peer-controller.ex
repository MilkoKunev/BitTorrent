defmodule BitTorrent.Peer.Controller do
  use GenServer

  require Logger

  @interval 10000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, __MODULE__)
  end

  def init(args) do
    schedule_interval()
    {:ok, args}
  end

  def handle_info({ref, result}, state) do
    # TODO: save received peers
    case result do
      {:error, reason} ->
        Logger.info("Error in receiving peers: #{reason}")
      {:ok, {info_hash, peers}} ->

    end
    {:noreply, state}
  end

  def handle_info(:get_peers, state) do
    get_peers(state)
    {:noreply, state}
  end

  defp get_peers([]), do: []

  defp get_peers([head | tail]) do
    Task.Supervisor(BitTorrent.TaskSupervisor, fn ->
      BitTorrent.Peer.Request.send(head)
    end)
    get_peers(tail)
  end

  defp schedule_interval() do
    Process.send_after(__MODULE__, :get_peers, interval)
  end
end
