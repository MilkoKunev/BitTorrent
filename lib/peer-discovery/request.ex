defmodule BitTorrent.Discovery.Request do

  def send({info_hash, announce_url}) do
    IO.inspect("Sending request")
    params = %{
      info_hash: info_hash,
      peer_id: Application.get_env(:bittorrent, :client_id),
      port:  Application.get_env(:bittorrent, :port)
    }

    handle_response(
      HTTPoison.get(announce_url,
          [{"Accept", "application/json"}],
          params: params), info_hash
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
