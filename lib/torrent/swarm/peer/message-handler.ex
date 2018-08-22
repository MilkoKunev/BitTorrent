defmodule BitTorrent.Peer.Message.Handler do

  alias BitTorrent.Torrent.File.BitField, as: BitFieldServer
  alias BitTorrent.Message

  require Logger

  def handle_message({:bitfield, bitfield}, state) do
    Logger.info("Handling bitfield message")
    peer_bitfield = BitFieldSet.new!(bitfield, bit_size(bitfield))
    message = Message.build(:interested)
    state = %{state | peer_bitfield: peer_bitfield, am_interested: true}
    {state, message}
  end

  def handle_message({:have, piece_index}, state) do
    Logger.info("Handling have message")
    peer_bitfield = BitFieldSet.put(state.peer_bitfield, piece_index)
    state = %{state | peer_bitfield: peer_bitfield}
    {state, nil}
  end

  def handle_message({:choke}, state) do
    Logger.info("Handling choke message")
    case BitFieldServer.get_available_pieces.full?(state.bitfield_name) do
      true ->
        %{state | peer_choking: true, am_interested: false}
        {state, Message.build(:not_interested)}
      false ->
        %{state | peer_choking: true, am_interested: true}
        {state, Message.build(:interested)}
    end
  end

  def handle_message({:unchoke}, %{peer_choking: choking, current_offset: offset, piece_length: length, current_piece: piece} = state)
    when choking == true
    and (piece == nil or offset >= length) do
      [piece | pieces_tail] = state.pieces_indexes
      {state, message} = _create_request_message(%{state | peer_choking: false, current_piece: piece, pieces_indexes: pieces_tail, current_offset: 0})
  end

  def handle_message({:unchoke}, %{peer_choking: choking, current_offset: offset, piece_length: length} = state)
    when choking == true and offset < length do
      Logger.info("Handling unchoke message")
      {state, message} = _create_request_message(%{state | peer_choking: false})
  end

  def handle_message({:unchoke}, state) do
    Logger.info("Wont't handle unchoke message, because client is unchoked")
    {state, nil}
  end

  def handle_message({:piece, index, begin, block}, %{current_offset: offset, piece_length: length, current_piece: piece} = state)
    when offset < length do
      BitFieldServer.put_piece(state.bitfield_name, index)
      {state, message} = _create_request_message(state)
  end

  def handle_message({:piece, index, begin, block}, %{current_offset: offset, piece_length: length, current_piece: piece} = state)
    when piece == nil or offset >= length do
      Logger.info("Received full piece and choosing another")
      BitFieldServer.put_piece(state.bitfield_name, index)
      [piece | pieces_tail] = state.pieces_indexes
      {state, message} = _create_request_message(%{state | current_piece: piece, pieces_indexes: pieces_tail, current_offset: 0})
  end

  def handle_message({:keep_alive}, state) do
      {state, nil}
  end

  def handle_message({:unknown, _binary}, state) do
    {state, nil}
  end

  defp _create_request_message(state) do
    if BitFieldServer.full?(state.bitfield_name) == true do
      {state, :download_complete}
    else
      case BitFieldServer.is_member?(state.bitfield_name, state.current_piece) do
        false ->
          request_message = Message.build(:request, state.current_piece, state.current_offset, state.block_length)
          {%{state | current_piece: state.current_piece, current_offset: state.current_offset + state.block_length}, request_message}
        true ->
          [piece | tail] = state.pieces_indexes
          _create_request_message(%{state | current_piece: piece, pieces_indexes: tail})
      end
    end
  end

end
