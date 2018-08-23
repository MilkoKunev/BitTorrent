defmodule BitTorrent.Torrent.File.BitField.Test do
  use ExUnit.Case, async: true

  alias BitTorrent.Torrent.File.BitField, as: BitFieldServer
  setup do
    bitfield = BitFieldSet.new!(<<0b00000000>>, 8)
    {:ok, pid} = BitFieldServer.start_link([bitfield: bitfield, name: :bitfield_test_1])
    {:ok, %{server: pid}}
  end

  test "check if piece is member", %{server: server} do
    assert BitFieldServer.is_member?(server, 0) == false
  end

  test "if piece is flag of updated piece is up", %{server: server} do
     BitFieldServer.put_piece(server, 0)
     assert BitFieldServer.is_member?(server, 0) == true
  end

  test "piece can be unflagged from bitfield", %{server: server} do
    BitFieldServer.put_piece(server, 0)
    BitFieldServer.delete_piece(server, 0)
    assert BitFieldServer.is_member?(server, 0) == false
  end

  test "get downloaded pieces", %{server: server} do
    BitFieldServer.put_piece(server, 0)
    [piece | _tail] = BitFieldServer.get_available_pieces(server)
    assert piece == 0
  end

  test "get remaining piece", %{server: server} do
    piece = BitFieldServer.get_remaining_piece(server, [0, 1, 2, 3, 4, 5, 6, 7, 8])
    assert piece == 0
  end

end
