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
    IO.inspect("BitField message")
    # length = bit_size(message.bitfield) - 1
    IO.inspect message
    IO.inspect bit_size(message.bitfield)
    peer_bitfield = BitFieldSet.new!(message.bitfield, message.length)
    interested = Message.build(:interested)
    :gen_tcp.send(socket, interested)
    :inet.setopts(socket, active: :once)
    {:noreply, %{state | peer_bitfield: peer_bitfield, am_interested: true}}
  end

  def handle_cast({:have, message, socket}, state) do
    IO.inspect("Have message")
    peer_bitfield = BitFieldSet.put(state.peer_bitfield, message.piece_index)
    {:noreply, %{state | peer_bitfield: peer_bitfield}}
  end

  def handle_cast({:choke, message, socket}, state) do
    IO.inspect("choke message")
    # TODO: Start keep alive message and in the first time send interested message
    # state = %{state | am_interested: false, peer_choking: true}
    # schedule_keep_alive_msg(state)
    {:noreply, %{state | am_interested: false, peer_choking: true}}
  end

  def handle_cast({:unchoke, message, socket}, state) do
    IO.inspect("unchoke message")

    # request = Message.build(:request)
    # :gen_tcp.send(socket, interested)
    # :inet.setopts(socket, active: :once)
    {:noreply, %{state | peer_choking: false}}
  end

  def handle_cast({:keep_alive, message, socket}, state) do
    IO.inspect("keep-alive message")
    # interested = Message.build(:keep_alive)
    # :gen_tcp.send(socket, interested)
    {:noreply, state}
  end

  def handle_cast({:piece, message, socket}, state) do
    IO.inspect("piece message")
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

  # TODO: Add interested, not_interested
end
