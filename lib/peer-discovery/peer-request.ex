defmodule BitTorrent.Peer.Request do
  def send(data) do
    params = %{
      info_hash: data.info_hash,
      peer_id: data.peer_id,
      port: data.port
    }
    handle_response(
      HTTPoison.get(data.announce_url, [{"Accept", "application/json"}], params: data), info_hash
    )
  end

  defp handle_response(response, info_hash) do
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, {info_hash, Map.get(Bento.decode!(body), "peers")}}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, Bento.decode!(reason)}
    end
  end
end
