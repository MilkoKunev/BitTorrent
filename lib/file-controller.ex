defmodule BitTorrent.File.Controller do

  @torrents_dir Application.get_env(:bittorrent, :torrentsdir)

  def read_torrent(torrent_file) when is_bitstring(torrent_file) do
    file_path = @torrents_dir <> torrent_file

   case File.exists?(file_path) do
      true ->
        case File.read!(file_path) |> Bento.decode() do
          {:ok, torrent} ->
            info_hash = :crypto.hash(:sha, Bento.encode!(Map.get(torrent, "info")))
            torrent = Map.put(torrent, "info_hash", info_hash)
            {:file, torrent}
          {:error, _reason} ->
            {:file, :not_torrent_file}
        end
      false ->
        {:file, :not_found}
    end
  end

  def read_torrent(_torrent) do
    {:file, :not_string}
  end

  def get_torrents() do
    dir = Application.get_env(:bittorrent, :torrentsdir)
    Path.wildcard(dir <> "*.torrent")
    |> Enum.map(fn(torrent) ->
      String.replace(torrent, dir, "")
    end)
  end

end
