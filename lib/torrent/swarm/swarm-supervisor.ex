defmodule BitTorrent.Swarm.Sup do
  use Supervisor

  alias BitTorrent.Utils

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args[:torrent], name: args[:name])
  end

  def init(torrent) do
    peer_sup_name = Utils.generate_id()

    children = [
      %{
        id: peer_sup_name,
        start: {BitTorrent.Peer.Sup, :start_link, [[torrent: torrent, name: peer_sup_name]]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

end
