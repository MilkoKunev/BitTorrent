defmodule BitTorrent.Swarm.Sup do
  use Supervisor

  def start_link(peers) do
    Supervisor.start_link(__MODULE__, )
  end


end
