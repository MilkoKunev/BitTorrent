defmodule BitTorrent.Torrent.File.BitField do

  use Agent

  def start_link(args) do
    Agent.start_link(fn -> args[:bitfield] end, name: args[:name])
  end

  def is_member?(agent, piece_index) do
    Agent.get(agent, fn bitfield ->
      BitFieldSet.member?(bitfield, piece_index)
    end)
  end

  def put_piece(agent, piece_index) do
    Agent.update(agent, fn bitfield ->
      BitFieldSet.put(bitfield, piece_index)
    end)
  end

  def delete_piece(agent, piece_index) do
    Agent.update(agent, fn bitfield ->
      BitFieldSet.delete(bitfield, piece_index)
    end)
  end

  def full?(agent) do
    Agent.get(agent, fn bitfield ->
      BitFieldSet.full?(bitfield)
    end)
  end

  def get_available_pieces(agent) do
    Agent.get(agent, fn bitfield ->
      BitFieldSet.to_list(bitfield)
    end)
  end

  def get_remaining_piece(agent, current_list) do
    Agent.get(agent, fn bitfield ->
      [remaining_piece | _tail] = current_list -- BitFieldSet.to_list(bitfield)
      remaining_piece
    end)
  end

end
