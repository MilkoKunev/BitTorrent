defmodule BitTorrent.CLI do


  @commands %{
    "@start_download #torrent_name" => "start downloading @torrent_name",
    "@check_torrents" => "check available torrent files"
  }

  def main() do
    IO.puts("\nWelcome to BitTorrent v.0.0.0.1!")
    print_help_message()
    receive_command()
  end

  defp receive_command() do
    cmd = IO.gets("> ")
    |> String.trim
    |> String.downcase

    torrent = case cmd do
       <<"@check_torrents", _rest::bytes>> ->
         case BitTorrent.File.Controller.get_torrents() do
          [] ->
            IO.puts("No torrents in torrents dir")
          list ->
              Enum.each(list, fn(torrent) ->
                IO.puts(torrent)
              end)
         end
         receive_command()
       <<"@start_download", _whitespace::size(8), torrent::bytes>> ->
         case BitTorrent.File.Controller.read_torrent(torrent) do
            {:file, :not_torrent_file} ->
              IO.puts("Not a torrent file")
              receive_command()
            {:file, :not_found} ->
              IO.puts("File was not found")
              receive_command()
            {:file, :not_string} ->
              IO.puts("Entered data was not string")
              receive_command()
            {:file, torrent} ->
              torrent
         end
       <<"@help", _rest::bytes>> ->
         print_help_message()
         receive_command()
       _ ->
         IO.puts("No such command, you can use @help")
         receive_command()
     end

     IO.inspect(torrent)
     start_torrent(torrent)
  end

  defp print_help_message do
    IO.puts("\nEltorrent supports following  commands:\n")
    @commands
    |> Enum.map(fn({command, description}) ->
         IO.puts("  #{command} - #{description}")
    end)
  end

  def start_torrent(torrent) do
    spec = %{
      id: :torrent,
      start: {BitTorrent.Torrent.Sup, :start_link, [[torrent: torrent]]},
      type: :supervisor
    }

    DynamicSupervisor.start_child(BitTorrent.Torrents.Sup, spec)
end


end
