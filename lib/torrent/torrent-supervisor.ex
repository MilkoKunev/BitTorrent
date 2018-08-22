defmodule BitTorrent.Torrent.Sup do
  use Supervisor

  alias BitTorrent.Utils

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args[:torrent])
  end

  def init(torrent_info) do
    client_id = Application.get_env(:bittorrent, :client_id)
    port = Application.get_env(:bittorrent, :port)
    block_length = Application.get_env(:bittorrent, :block_length)

    announce = Map.get(torrent_info, "announce")
    info = Map.get(torrent_info, "info")
    info_hash = Map.get(torrent_info, "info_hash")
    piece_length = Map.get(info, "piece length")
    length = Map.get(info, "length")
    pieces = Map.get(info, "pieces")
    name = Map.get(info, "name")

    peers =
      BitTorrent.Discovery.Controller.get_peers(info_hash, announce)
      |> Enum.filter(fn peer ->
          Map.get(peer, "peer id") != client_id
      end)

    torrent = Torrent.new(info_hash, piece_length, length, pieces, name, block_length, peers)

    swarm_name = Utils.generate_id()

    bitfield_size = torrent.bitfield_length
    bitfield_name = Utils.generate_id()
    bitfield = BitFieldSet.new!(<<0::size(bitfield_size)>>, bitfield_size)

    file_server_name = Utils.generate_id()

    # TODO: Think of a better way for updating servers' names
    torrent = %{torrent | bitfield_name: bitfield_name, file_name: file_server_name}

    file_supervisor_name = Utils.generate_id()

    children = [
      %{
        id: bitfield_name,
        start: {BitTorrent.Torrent.File.BitField, :start_link, [[bitfield: bitfield, name: bitfield_name]]},
        type: :worker
      },
      %{
        id: swarm_name,
        start: {BitTorrent.Swarm.Sup, :start_link, [[torrent: torrent, name: swarm_name]]},
        type: :supervisor
      },
      %{
        id: file_server_name,
        start: {BitTorrent.Torrent.File.Sup, :start_link, [[name: file_supervisor_name, file_server_name: file_server_name, file_name: torrent.name]]},
        type: :supervisor
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
