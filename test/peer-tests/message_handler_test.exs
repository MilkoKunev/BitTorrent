defmodule BitTorrent.Peer.Message.Handler.Test do
  use ExUnit.Case, async: true

  alias BitTorrent.Message
  alias BitTorrent.Peer.Message.Handler
  alias BitTorrent.Torrent.File.BitField, as: BitFieldServer

  require Logger

  setup do
    torrent = Torrent.new("info_hash", 131072, 104857600, "pieces", "demo.file.torrent", 16384, ["peer1", "peer2"])
    bitfield = BitFieldSet.new!(<<0b00110011>>, 8)
    {:ok, pid} = BitFieldServer.start_link([bitfield: bitfield, name: :bitfield_test])
    torrent = %{torrent | peer_bitfield: bitfield, bitfield_name: :bitfield_test}
    {:ok, %{torrent: torrent}}
  end

  test "update state on bitfield handle message", %{torrent: state} do
    state = %{state | peer_bitfield: nil}
    bitfield = <<0b00110011>>
    {state, _message} = Handler.handle_message({:bitfield, bitfield}, state)
    assert state.peer_bitfield != nil
  end

  test "created interested message on bitfield handle message and change am_interested to true", %{torrent: state} do
    state = %{state | peer_bitfield: nil}
    bitfield = <<0b00000000>>
    {state, <<_length::size(32), payload>>} = Handler.handle_message({:bitfield, bitfield}, state)
    decoded_msg = Message.decode(<<payload>>)
    assert decoded_msg == {:interested} && state.am_interested != false
  end

  test "handle have message and update peer_bitfield", %{torrent: state} do
    piece_index = 0
    {state, nil} = Handler.handle_message({:have, piece_index}, state)
    assert BitFieldSet.member?(state.peer_bitfield, piece_index)
  end

  test "handle unchoke message if send while being already unchoked", %{torrent: state} do
    state = %{state | peer_choking: false}
    {state, message} = Handler.handle_message({:unchoke}, state)
    assert message == nil
  end

  test "handle unchoke message if send after being choked and already having a piece", %{torrent: state} do
    state = %{state | current_piece: 0}
    {state, <<_length::size(32), payload::bytes>>} = Handler.handle_message({:unchoke}, state)
    {type, index, _offset, _length} = Message.decode(payload)
    assert type == :request && index == 0
  end

  test "handle unchoke message if current_piece is not set", %{torrent: state} do
    {state, <<_length::size(32), payload::bytes>>} = Handler.handle_message({:unchoke}, state)
    {type, index, _offset, _length} = Message.decode(payload)
    assert type == :request && state.current_piece != nil
  end

  test "handle unchoke message if already got every block of a piece", %{torrent: state} do
    [_piece | tail] = state.pieces_indexes
    state = %{state| current_offset: 131072, current_piece: 0, pieces_indexes: tail}
    {state, <<_length::size(32), payload::bytes>>} = Handler.handle_message({:unchoke}, state)
    {type, index, _offset, _length} = Message.decode(payload)
    assert type == :request && state.current_piece == 1
  end

  test "handle choke message if bitfield server is not full", %{torrent: state} do
    {state, <<_length::size(32), payload::bytes>>} = Handler.handle_message({:choke}, state)
    {type} = Message.decode(payload)
    assert state.peer_choking == true && type == :interested
  end

end
