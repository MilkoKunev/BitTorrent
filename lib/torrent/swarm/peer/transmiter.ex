defmodule BitTorrent.Peer.Transmiter do

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: args[:name])
  end

  def send_message(server, message, socket) do
    GenServer.cast(server, {:message, message, socket})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:message, message, socket}, state) do
    :gen_tcp.send(socket, message)
    {:noreply, state}
  end

end
