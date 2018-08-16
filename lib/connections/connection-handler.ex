defmodule BitTorrent.Connection.Handler do

  use GenServer

  def start_link() do
    GenServer.call(__MODULE__, %{})
  end

  def create_socket(address, port, info_hash, peer_id, pid) do
    request = {:create_socket, address, port, info_hash, peer_id, pid}
    GenServer.call(__MODULE__, request)
  end

  # CALLBACKS
  def init(state) do
    {:reply, state}
  end

  def handle_call({:create_socket, address, port, info_hash, peer_id, pid}, from, state) do
    handshake = Message.build(:handshake, address, port, info_hash, peer_id)

    case :gen_tcp.connect(to_charlist(address), port, [:binary]) do
      {:ok, socket} ->
        :gen_tcp.send(socket, handshake)
        Task.Supervisor.async_nolink(BitTorrent.TaskSupervisor, fn ->
          data = :gen_tcp.recv(socket, 0)
          reply_with_socket(data, state)
        end)
        {:noreply, Map.put(state, peer_id, {address, info_hash, pid, from, socket})}
      {_, _} ->
        {:reply, :error, state}
      end
  end

  defp reply_with_socket(data, state) do
    msg = Message.decode(data)
    socket_info = Map.get(state, data.peer_id)
    :gen_tcp.controlling_process(socket_info.pid, socket_info.socket)
    GenServer.reply(socket_info.from, socket_info.socket)
  end

end
