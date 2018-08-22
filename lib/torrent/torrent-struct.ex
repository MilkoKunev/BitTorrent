defmodule Torrent do
    defstruct(
     info_hash: nil,
     piece_length: nil,
     bitfield_length: nil,
     length: nil,
     pieces: nil,
     pieces_indexes: [],
     current_piece: nil,
     current_offset: 0,
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
     bitfield_name: nil,
     file_name: nil
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
        }
        |> calculate_bitfield_length()
        |> create_piece_list()
    end

    def add_server_names(torrent, controller, receiver, transmiter) do
        %{torrent | controller_name: controller, receiver_name: receiver, transmiter_name: transmiter}
    end

    defp calculate_bitfield_length(torrent) do
        value = torrent.length / torrent.piece_length
        value = case value do
            value when value == 0 ->
                trunc(value) - 1
            _ ->
                trunc(value)
        end
        %{torrent | bitfield_length: value}
    end

    defp create_piece_list(torrent) do
        %{torrent | pieces_indexes: Enum.to_list(0..torrent.bitfield_length)}
    end

end

