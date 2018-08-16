defmodule Bittorrent.Application do

  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: BitTorrent.TaskSupervisor},
      {BitTorrent.Peer.Sup, [name: Peer.Supervisor]},
      {DynamicSupervisor, name: BitTorrent.Torrents.Sup}
    ]

    opts = [strategy: :one_for_one, name: Bittorrent.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
