defmodule Opis.Server do
  @moduledoc false

  use GenServer

  # alias Opis.Call

  defmodule State do
    @type t :: %__MODULE__{application: atom() | nil, ets_table: :ets.table(), processes: [pid()]}
    defstruct [:application, :ets_table, processes: []]
  end

  ## Client

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start_tracing(pid \\ self()) do
    GenServer.call(__MODULE__, {:start_tracing, pid})

    :erlang.trace(pid, true, [:call, tracer: Process.whereis(__MODULE__)])
    :erlang.trace_pattern({:_, :_, :_}, [{:_, [], [{:return_trace}]}], [:local])
  end

  def stop_tracing(pid \\ self()) do
    GenServer.call(__MODULE__, {:stop_tracing, pid})

    :erlang.trace_pattern({:_, :_, :_}, false, [:local])
    :erlang.trace(pid, false, [:call, tracer: Process.whereis(__MODULE__)])

    # Ensure all traces are delivered
    :erlang.trace_delivered(Process.whereis(__MODULE__))

    receive do
      {:trace_delivered, _, _} -> :ok
    end
  end

  def calls(pid \\ self()) do
    # Since `call` sends a message and waits for a reply, when this `call`
    # returns we can be assured that the server has processed all tracing
    # messages since messages are processed sequentially.
    :ok = GenServer.call(__MODULE__, :ensure_finished)
    # {:ok, calls.children}
    # TODO Reduce down the ETS table to a tree
  end

  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  def clear(pid) do
    GenServer.call(__MODULE__, {:clear, pid})
  end

  ## Server

  def init(_opts) do
    {:ok, %State{ets_table: :ets.new(:opis_calls, [:ordered_set])}}
  end

  def handle_info({:trace, pid, :call, call}, state) do
    if pid in state.processes do
      :ets.insert(table, {generate_id(table), :call, call})
    end

    {:noreply, state}
  end

  def handle_info({:trace, _pid, :return_from, call, value}, %State{ets_table: table} = state) do
    :ets.insert(table, {generate_id(table), :return, call, value})

    {:noreply, state}
  end

  defp generate_id(table) do
    case :ets.last(table) do
      :"$end_of_table" -> 0
      num -> num + 1
    end
  end

  def handle_call({:start_tracing, pid}, _from, %State{processes: processes} = state) do
    {:reply, :ok, %State{state | processes: [pid | processes]}}
  end

  def handle_call({:stop_tracing, pid}, _from, %State{processes: processes} = state) do
    {:reply, :ok, %State{state | processes: List.delete(processes, pid)}}
  end

  # TODO: Reimplement this
  # def handle_call({:clear, pid}, _from, state) do
  #   {:reply, :ok, Map.delete(state, pid)}
  # end
end
