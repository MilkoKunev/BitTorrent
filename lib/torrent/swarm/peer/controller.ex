defmodule BitTorrent.Peer.Controller do

  use GenServer

  defstruct(
    bitfield: [],
    info_hash: "",

  )

end
