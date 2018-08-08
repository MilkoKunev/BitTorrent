defmodule Bittorrent.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Task.Supervisor, name: BitTorrent.TaskSupervisor},
      {BitTorrent.Peer.Sup, [name: Peer.Supervisor]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bittorrent.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
