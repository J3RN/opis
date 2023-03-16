defmodule Opis.Server do
  use GenServer

  ## Client

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  ## Server

  def init(state) do
    {:ok, state}
  end

  def handle_info(:hello, state) do
    {:noreply, state}
  end

  def handle_call(:flush, state) do
    {:reply, :ok, state}
  end
end
