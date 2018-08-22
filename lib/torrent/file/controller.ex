defmodule BitTorrent.Torrent.File.Controller do

  use GenServer

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: args[:name])
  end

  def write_to_file(server, piece_index, offset, block_length, data) do
    GenServer.cast(server, {:write, piece_index, offset, block_length, data})
  end

  def completed_downloading(server) do
    GenServer.cast(server, :completed)
  end

  def init(args) do
    dir = Application.get_env(:bittorrent, :downloadsdir)
    {:ok, io_device} = File.open(dir <> args[:file_name], [:binary, :read, :write])
    {:ok, %{file: io_device}}
  end

  def handle_cast(:completed, state) do
    File.close(state[:file])
    {:noreply, %{state | file: nil}}
  end

  def handle_cast({:write, 0, 0, _piece_length, data}, state) do
    Logger.info("Received block with index 0 and offset 0 ")
    IO.binwrite(state.file, data)
    {:noreply, state}
  end

  def handle_cast({:write, 0, offset, _piece_length, data}, state) do
    Logger.info("Received block with index 0 and offset #{offset}")
    :file.position(state.file, offset)
    IO.binwrite(state.file, data)
    {:noreply, state}
  end

  def handle_cast({:write, piece_index, 0, piece_length, data}, state) do
    Logger.info("Received block with index #{piece_index} and offset 0")
    offset = piece_index * piece_length
    :file.position(state.file, offset)
    IO.binwrite(state.file, data)
    {:noreply, state}
  end

  def handle_cast({:write, piece_index, offset, piece_length, data}, state) do
    Logger.info("Received block with index #{piece_index} and #{offset}")
    offset = (piece_index * piece_length) + offset
    :file.position(state.file, offset)
    IO.binwrite(state.file, data)
    {:noreply, state}
  end


end
