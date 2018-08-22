defmodule BitTorrent.Swarm.Sup do
  use Supervisor

  alias BitTorrent.Utils

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args[:torrent])
  end

  def init(torrent) do
    {torrent, children} = create_children_specs(torrent.peers, torrent, [])
    Supervisor.init(children, strategy: :one_for_all)
  end

  defp create_children_specs([], torrent, acc) do
    {torrent, acc}
  end

  defp create_children_specs([peer | tail], torrent, acc) do
    controller_name = Utils.generate_id()
    receiver_name = Utils.generate_id()
    transmiter_name = Utils.generate_id()

    torrent = Torrent.add_server_names(torrent, controller_name, receiver_name, transmiter_name)

    controller_spec = %{
      id: torrent.controller_name,
      start: {BitTorrent.Peer.Controller,
      :start_link,
      [[name: torrent.controller_name, torrent: torrent]]},
      type: :worker,
      restart: :temporary
    }

    acc = [controller_spec | acc]

    peer_address = Map.get(peer, "ip")
    peer_id = Map.get(peer, "peer id")
    port = Map.get(peer, "port")

    receiver_spec = %{
      id: torrent.receiver_name,
      start: {
        BitTorrent.Peer.Receiver,
        :start_link,
        [
          [
            address: peer_address,
            peer_id: peer_id,
            port: port,
            name: torrent.receiver_name,
            info_hash: torrent.info_hash,
            controller_name: torrent.controller_name,
            restart: :temporary
          ]
        ]
      }
    }

    acc = [receiver_spec | acc]

    transmiter_spec = %{
      id: torrent.transmiter_name,
      start: {
        BitTorrent.Peer.Transmiter,
        :start_link,
        [[name: torrent.transmiter_name, controller_name: torrent.controller_name]]
      },
      restart: :temporary
    }

    acc = [transmiter_spec | acc]

    create_children_specs(tail, torrent, acc)
  end
end
