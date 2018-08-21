defmodule Bittorrent.Application do

  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, [name: BitTorrent.TaskSupervisor, type: :supervisor]},
      {BitTorrent.Discovery.Sup, [name: Discovery.Supervisor, type: :supervisor]},
      {DynamicSupervisor, [strategy: :one_for_one, name: BitTorrent.Torrents.Sup, type: :supervisor]},
      {BitTorrent.Connection.Handler, []}
    ]

    opts = [strategy: :one_for_one, name: Bittorrent.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
