defmodule BitTorrent.Peer.Controller do

  use GenServer

  alias BitTorrent.Connection.Handler
  alias BitTorrent.Message

  def start_link(args) do
    IO.inspect("From controller process")
    GenServer.start_link(__MODULE__, args[:torrent], name: args[:name])
  end

  def handle_message(server, message, socket) do
    GenServer.cast(server, {message.type, message, socket})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:bitfield, message, socket}, state) do
    IO.inspect("Sending msg")
    IO.inspect(message)
    interested = Message.build(:interested)
    IO.inspect Message.decode(interested)
    :timer.sleep(10000)
    :gen_tcp.send(socket, interested)
    :inet.setopts(socket, active: true)
    {:noreply, %{state | peer_bitfield: message.bitfield, am_interested: true}}
  end

  def handle_cast({:choke, message, socket}, state) do
    IO.inspect("Sending msg")
    IO.inspect(message)
    # interested = Message.build(:interested)
    # :gen_tcp.send(socket, interested)
    # :inet.setopts(socket, active: :once)
    {:noreply, %{state | peer_choking: true}}
  end

  def handle_cast({:unchoke, message, socket}, state) do
    IO.inspect("Sending msg")
    IO.inspect(message)
    # interested = Message.build(:interested)
    # :gen_tcp.send(socket, interested)
    # :inet.setopts(socket, active: :once)
    {:noreply, %{state | peer_choking: false}}
  end

  def handle_cast({:keep_alive, message, socket}, state) do
    IO.inspect("Sending msg")
    IO.inspect(message)
    interested = Message.build(:keep_alive)
    :gen_tcp.send(socket, interested)
    {:noreply, state}
  end

  def handle_cast({:piece, message, socket}, state) do
    IO.inspect("Sending msg")
    IO.inspect(message)
    # interested = Message.build(:interested)
    # :gen_tcp.send(socket, interested)
    # :inet.setopts(socket, active: :once)
    {:noreply, %{state | peer_bitfield: message.bitfield}}
  end

  def handle_cast({:unknown, _message, _socket}, state) do
    IO.inspect("Unknown msg")
    # interested = Message.build(:interested)
    # :gen_tcp.send(socket, interested)
    # :inet.setopts(socket, active: :once)
    {:noreply, state}
  end

end
