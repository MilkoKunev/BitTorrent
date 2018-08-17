defmodule BitTorrent.Peer.Receiver do

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    BitTorrent.Connection.Handler.create_socket(address, port, info_hash, peer_id, self())
    {:noreply, state}
  end

  def handle_info({:tcp, socket, msg}, state) do
      :inet_setopts(socket, {active, once})
  end


  def handle_info({:tcp_closed, socket}, state) do

    {:noreply, state}
  end

end
