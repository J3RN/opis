defmodule Opis.Server do
  use GenServer

  defmodule Call do
    @type t :: %__MODULE__{call: {module(), atom(), [term()]}, children: [t()], return: term()}
    defstruct [:call, :return, children: []]
  end

  defmodule State do
    @type t :: %__MODULE__{calls: [Call.t()], path: [term()]}
    defstruct calls: %Call{}, path: []
  end

  ## Client

  def start_link() do
    GenServer.start_link(__MODULE__, %State{})
  end

  ## Server

  def init(state) do
    {:ok, state}
  end

  def handle_info(:hello, state) do
    {:noreply, state}
  end

  def handle_call(:flush, _from, state) do
    {:reply, :ok, state}
  end
end
