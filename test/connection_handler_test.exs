defmodule BitTorrent.Connection.Handler.Test do
  use ExUnit.Case, async: true

  setup do
    {:ok, pid} = BitTorrent.Connection.Handler.start_link([])
    {:ok, _pid} = Supervisor.start_link([{Task.Supervisor, [name: BitTorrent.TaskSupervisor, type: :supervisor]}], strategy: :one_for_one)
    state =
      %{
        server: pid,
        info_hash: "01234567890123456789",
        peer_id: "-qB3310-1234567890.f",
        host: "127.0.0.1",
        port: 8081
      }
    {:ok, state}
  end

  test "check if current task is receiving socket", state do
    Task.start_link(fn ->
      {:ok, socket} = :gen_tcp.listen(8081, [:binary, active: false, packet: :raw])
      {:ok, client} = :gen_tcp.accept(socket)
      {:ok, data} = :gen_tcp.recv(client, 0)
      :gen_tcp.send(client, data)
      :gen_tcp.send(client, "Test passed")
    end)
    {:ok, socket} = BitTorrent.Connection.Handler.create_socket(state.host, state.port, state.info_hash, state.peer_id)
    {:ok, data} = :gen_tcp.recv(socket, 0)
    assert data == "Test passed"
  end
end
