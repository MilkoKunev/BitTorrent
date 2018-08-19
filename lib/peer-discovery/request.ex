defmodule BitTorrent.Discovery.Request do

  @peer_id "-qB3310-1234567890.f"
  @port 6881

  def send({info_hash, announce_url}) do
    IO.inspect("Sending request")
    params = %{
      info_hash: info_hash,
      peer_id: @peer_id,
      port: @port
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
