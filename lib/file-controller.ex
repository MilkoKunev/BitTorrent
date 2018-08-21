defmodule BitTorrent.File.Controller do

  @torrents_dir "C:/Users/Milko Kunev/Desktop/Elixir/bittorrent/test/torrents/"

  def read_torrent(torrent_file) when is_bitstring(torrent_file) do
    file_path = @torrents_dir <> torrent_file

    case File.exists?(file_path) do
      true ->
        File.read!(file_path)
        |> Bento.decode!()
      false ->
        {:file, :not_found}
    end
  end

end
