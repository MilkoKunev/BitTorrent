defmodule BitTorrent.Message do

  require Logger

  # used in handshake msg
  @pstr "BitTorrent protocol"
  @pstrlen 19
  @reserved_bits << 0 :: size(64) >>
  @block_length 16384

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
    <<@pstrlen, @pstr, @reserved_bits, info_hash::bytes-size(20), peer_id::bytes-size(20)>>
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

  def build(:request, index, offset, length) do
    <<@request_length::size(32), @request_id::size(8), index::size(32), offset::size(32), length::size(32)>>
  end

  def build(:keep_alive) do
    <<@keep_alive_length::size(32)>>
  end

  # TODO: Add build methods for :have, :bitfield, :piece, when acceptor/listener is implemeented

  def decode(<<@keep_alive_length::size(32), rest::bytes>>) do
    %{
      type: :keep_alive
    }
  end

  def decode(<<@state_length::size(32), @choke_id::size(8)>>) do
    %{
      type: :choke
    }
  end

  def decode(<<@state_length::size(32), @unchoke_id::size(8)>>) do
    %{
      type: :choke
    }
  end

  def decode(<<@state_length::size(32), @interested_id::size(8)>>) do
    %{
      type: :interested
    }
  end

  def decode(<<@state_length::size(32), @not_interested_id::size(8)>>) do
    %{
      type: :not_interested
    }
  end

  def decode(<<@have_length::size(32), @have_id::size(8), piece_index::bytes-size(4)>>) do
    %{
      type: :have,
      piece_index: piece_index
    }
  end

  def decode(<<length::size(32), @bitfield_id::size(8)>>) do
    %{
      type: :bitfield,
      bitfield: bitfield
    }
  end

  def decode(<<@length::size(32), @piece_id::size(8), index::size(32), begin::size(32)>>) do
    %{
      type: :piece,
      index: index,
      offset: begin,
      block: rest
     }
  end

  def decode(binary) do
    %{
      type: :unknown
    }
  end

    # TODO: Add request decode message when acceptor/listener is implemented

end
