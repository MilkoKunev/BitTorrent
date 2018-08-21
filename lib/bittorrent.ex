defmodule BitTorrent.CLI do

  def read_file() do
    a = BitTorrent.File.Controller.read_torrent("demo-1.bin.torrent")
    info_hash = :crypto.hash(:sha, Bento.encode!(Map.get(a, "info")))
    Map.put(a, "info_hash", info_hash)
  end

  def get_peers(torrent) do
    BitTorrent.Discovery.Controller.get_peers(Map.get(torrent, "info_hash"), Map.get(torrent, "announce"))
  end

  def start_torrent() do
    torrent = read_file()
    spec = %{
      id: :torrent,
      start: {BitTorrent.Torrent.Sup, :start_link, [[torrent: torrent]]},
      type: :supervisor
    }
    DynamicSupervisor.start_child(BitTorrent.Torrents.Sup, spec)
  end


end
