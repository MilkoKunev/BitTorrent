defmodule BitTorrent.Peer.Receiver do

  use GenServer

  alias BitTorrent.Connection.Handler
  alias BitTorrent.Message

  def start_link(args) do
    IO.inspect "FROM RECEIVER PROCESS"
    GenServer.start_link(__MODULE__, args, name: args[:name])
  end

  def get_state(server) do
    GenServer.call(server, :get_state)
  end

  def handle_call(:get_state, from, state) do
    {:reply, state, state}
  end

  def init(state) do
    pid = self()
    Task.Supervisor.async_nolink(BitTorrent.TaskSupervisor, fn ->
      # TODO: handle error
      {:ok, socket} = Handler.create_socket(state[:address], state[:port], state[:info_hash], state[:peer_id])
      :gen_tcp.controlling_process(socket, pid)
      socket
    end)
    {:ok, %{controller: state[:controller_name]}}
  end

  def handle_info({:tcp, socket, msg}, state) do
      IO.inspect("RECEIVED MESSAGE RECIEVER")
      message = Message.decode(msg)
      BitTorrent.Peer.Controller.handle_message(state.controller, message, socket)
      {:noreply, state}
  end


  def handle_info({:tcp_closed, socket}, state) do
    IO.inspect("Socket closed")
    {:noreply, state}
  end

  def handle_info({ref, socket}, state) do
    IO.inspect "HANDLE INFO"
    :inet.setopts(socket, active: :once)
    {:noreply, state}
  end

  def handle_info({:DOWN, _, _, _, _}, state) do
    IO.inspect ("Task ended")
    {:noreply, state}
  end

end
