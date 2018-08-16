defmodule BitTorrent.Message.API do

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

  # def encode(:handshake, args \\ %) do
  #   build_message()
  # end



end
