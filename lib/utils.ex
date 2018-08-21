defmodule BitTorrent.Utils do

  def generate_id() do
    :crypto.strong_rand_bytes(10)
    |> Base.encode64(padding: false)
    |> String.to_atom
  end
end
