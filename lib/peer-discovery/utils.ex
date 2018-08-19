defmodule BitTorrent.Discovery.Utils do
  def insert_torrent(list, new_torrent) do
    [new_torrent | list]
    |> Enum.uniq
  end
end
