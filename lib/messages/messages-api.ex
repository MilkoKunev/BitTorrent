defmodule BitTorrent.Message do

  require Logger

  # used in handshake msg
  @pstr "BitTorrent protocol"
  @pstrlen 19
  @reserved_bits <<0::size(64)>>
  @block_length Application.get_env(:bittorrent, :block_length)

  # Fixed lengths
  @keep_alive_length 0
  # Next is length for
  # choke, unchoke, interested and not_interested
  @state_length 1
  @have_length 5
  @request_length 13
  @piece_length 9 + @block_length

  # Message IDs
  @choke_id 0
  @unchoke_id 1
  @interested_id 2
  @not_interested_id 3
  @have_id 4
  @bitfield_id 5
  @request_id 6
  @piece_id 7

  def build(:handshake, info_hash, peer_id) do
    <<@pstrlen::size(8), @pstr, @reserved_bits, info_hash::bytes-size(20), peer_id::bytes-size(20)>>
  end

  def build(:interested) do
    <<@state_length::size(32), @interested_id::size(8)>>
  end

  def build(:not_interested) do
    <<@state_length::size(32), @not_interested_id::size(8)>>
  end

  def build(:choke) do
    <<@state_length::size(32), @choke_id::size(8)>>
  end

  def build(:unchoke) do
    <<@state_length::size(32), @unchoke_id::size(8)>>
  end

  def build(:keep_alive) do
    <<@keep_alive_length::size(32)>>
  end

  def build(:request, index, offset, length) do
    <<@request_length::size(32), @request_id::size(8), index::size(32), offset::size(32), length::size(32)>>
  end

  # TODO: Add build methods for :have, :bitfield, :piece, when acceptor/listener is implemeented

  def decode_length(<<length::size(32)>>) do
    length
  end

  # def decode(message) do
  #   _decode(message, [])
  # end

  def decode() do
    {:keep_alive}
  end

  def decode(<<@pstrlen::size(8), pstr::bytes-size(@pstrlen), reserved::bytes-size(8), info_hash::bytes-size(20), peer_id::bytes-size(20)>>) do
    {:handshake, pstr, reserved, info_hash, peer_id, 68}
  end

  def decode(<<@choke_id::size(8)>>) do
    {:choke}
  end

  def decode(<<@unchoke_id::size(8)>>) do
    Logger.info("Decoding unchoke message")
    {:unchoke}
  end

  def decode(<<@interested_id::size(8)>>) do
    {:interested}
  end

  def decode(<<@not_interested_id::size(8)>>) do
    {:not_interested}
  end

  def decode(<<@have_id::size(8), piece_index::size(32)>>) do
    Logger.info("Decoding have message")
    {:have, piece_index}
  end

  def decode(<<@bitfield_id::size(8), bitfield::bytes>>) do
    Logger.info("Decoding BitField message")
    {:bitfield, bitfield}
  end

  def decode(<<@piece_id::size(8), index::size(32), begin::size(32), block::bytes-size(@block_length)>>) do
    Logger.info("Decoding piece message")
    Logger.info("Recieved block with index #{index}, with offset #{begin}")
    {:piece, index, begin, block}
  end

  def decode(<<@request_id::size(8), index::size(32), offset::size(32), length::size(32)>>) do
    Logger.info("Decoding request message")
    {:request, index, offset, length}
  end

  def decode(binary) do
    Logger.info("Decoding unknown message")
    Logger.info(byte_size(binary))
    {:unknown, binary}
  end

  # TODO: Add request decode message when acceptor/listener is implemented

end
