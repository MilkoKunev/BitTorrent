defmodule BitTorrent.Peer.Controller do

  use GenServer

  alias BitTorrent.Peer.Message.Handler, as: MessageHandler

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args[:torrent], name: args[:name])
  end

  def handle_messages(server, message, socket) do
    GenServer.cast(server, {:message, message, socket})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:message, message, socket}, state) do
    case {state, created_message} = MessageHandler.handle_message(message, state) do
      {state, nil} ->
        state
      {_state, :download_complete} ->
        Logger.info("Download complete :)")
      _ ->
        BitTorrent.Peer.Transmiter.send_message(state.transmiter_name, created_message, socket)
        state
    end
    {:noreply, state}
  end

end
