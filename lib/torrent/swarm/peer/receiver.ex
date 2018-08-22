defmodule BitTorrent.Peer.Receiver do

  use GenServer

  alias BitTorrent.Connection.Handler
  alias BitTorrent.Message

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: args[:name])
  end

  def get_state(server) do
    GenServer.call(server, :get_state)
  end

  def init(state) do
    pid = self()
    Task.Supervisor.async_nolink(BitTorrent.TaskSupervisor, fn ->
      # TODO: handle error
      {:ok, socket} = Handler.create_socket(state[:address], state[:port], state[:info_hash], state[:peer_id])
      :gen_tcp.controlling_process(socket, pid)
      socket
    end)
    {:ok, %{controller: state[:controller_name], socket: nil}}
  end

  def handle_info({ref, socket}, %{controller: controller} = state) do
    IO.inspect "HANDLE INFO"
    serve_socket(controller, socket)
    {:noreply, %{state | socket: socket}}
  end

  def handle_info({:DOWN, _, _, _, _}, state) do
    {:noreply, state}
  end

  def handle_call(:get_state, from, state) do
    {:reply, state, state}
  end

  defp serve_socket(controller_name, socket) do
    case :gen_tcp.recv(socket, 4) do
      {:ok, length} ->
        case length = Message.decode_length(length) do
          0 ->
            messages = Message.decode()
            BitTorrent.Peer.Controller.handle_messages(controller_name, messages, socket)
          _ ->
            case :gen_tcp.recv(socket, length) do
              {:ok, message} ->
                message = Message.decode(message)
                BitTorrent.Peer.Controller.handle_messages(controller_name, message, socket)
              {:error, reason} ->
                IO.inspect "ERROR receiving message"
                IO.inspect reason
            end
        end
      {:error, reason} ->
        IO.inspect "Error receving length"
        IO.inspect reason
    end
    serve_socket(controller_name, socket)
  end

end
