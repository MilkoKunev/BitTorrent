defmodule BitTorrent.Connection.Handler do

  use GenServer

  alias BitTorrent.Message

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def create_socket(address, port, info_hash, peer_id) do
    request = {:create_socket, address, port, info_hash, peer_id}
    GenServer.call(__MODULE__, request)
  end

  # CALLBACKS
  def init(state) do
    {:ok, state}
  end

  def handle_call({:create_socket, address, port, info_hash, peer_id}, from, state) do
    handshake = Message.build(:handshake, info_hash, peer_id)

    case :gen_tcp.connect(InetCidr.parse_address!(address), port, [:binary, active: false, packet: :raw]) do
      {:ok, socket} ->
        :gen_tcp.send(socket, handshake)
        Task.Supervisor.async_nolink(BitTorrent.TaskSupervisor, fn ->
          # Get only handshake message, which is exactly 68 bytes
          :gen_tcp.recv(socket, 68)
        end)
        # TODO: Set peer_id or something else as key. Problem:
        # Returned peer_id from handshake is different each time
        {:noreply, Map.put(state, info_hash, {info_hash, from, socket})}
      {:error, reason} ->
        {:reply, :error, state}
      end
  end

  def handle_info({ref, {:ok, data}}, state) do
    IO.inspect("RECEIVED MESSAGE")
    # TODO: Check if returned handshake is the same as our
    handshake =  Message.decode(data)
    key = Map.get(handshake, :info_hash)
    {_info_hash, from = {pid, _ref}, socket} = Map.get(state, key)
    case :gen_tcp.controlling_process(socket, pid) do
      :ok ->
        GenServer.reply(from, {:ok, socket})
      {:error, reason} ->
        GenServer.reply(from, {:error, reason})
    end
    {:noreply, state}
  end

  def handle_info({:DOWN, _, _, _, _}, state) do
    IO.inspect ("Task ended")
    {:noreply, state}
  end

end
