defmodule BitTorrent.Peer.Transmiter do

  use GenServer
  def start_link(args) do
    IO.inspect("From transmiter process")
    GenServer.start_link(__MODULE__, args, name: args[:name])
  end

  def get_state(server) do
    GenServer.call(server, :get_state)
  end

  # def send_msg(server, )

  def init(state) do
    {:ok, state}
  end

  def handle_call(:get_state, from, state) do
    {:reply, state, state}
  end
end
