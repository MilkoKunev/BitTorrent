defmodule BitTorrent.Torrent.Sup do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    peers = BitTorrent.Peer.Controller.get_peers(args.info_hash, args.announce_url)

  end

  defp create_children_specs([], acc) do
    acc
  end

  defp create_children_specs([peer_info | tail], other_info, acc) do

  end
end
