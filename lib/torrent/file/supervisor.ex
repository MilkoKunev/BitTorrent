defmodule BitTorrent.Torrent.File.Sup do

  use Supervisor


  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: args[:name])
  end

  def init(args) do
    children = [
      %{
        id: args[:file_server_name],
        start: {BitTorrent.Torrent.File.Controller, :start_link, [[name: args[:file_server_name], file_name: args[:file_name]]]},
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

end
