defmodule Torrent do
    defstruct(
     info_hash: nil,
     piece_length: nil,
     bitfield_length: nil,
     length: nil,
     pieces: nil,
     name: nil,
     block_length: nil,
     peers: [],
     peer_bitfield: nil,
     am_choking: true,
     am_interested: false,
     peer_choking: true,
     peer_interested: false,
     controller_name: nil,
     receiver_name: nil,
     transmiter_name: nil,
     bitfield_name: nil
    )

    def new(info_hash, piece_length, length, pieces, name, block_length, peers) do
        %Torrent{
            info_hash: info_hash,
            piece_length: piece_length,
            length: length,
            pieces: pieces,
            name: name,
            block_length: block_length,
            peers: peers,
        } |> calculate_bitfield_length()
    end

    def add_server_names(torrent, controller, receiver, transmiter) do
        %{torrent | controller_name: controller, receiver_name: receiver, transmiter_name: transmiter}
    end

    defp calculate_bitfield_length(torrent) do
        value = torrent.length / torrent.piece_length
        value = case value do
            value when value == 0 ->
                trunc(value)
            _ ->
                trunc(value) + 1
        end
        %{torrent | bitfield_length: value}
    end

end

