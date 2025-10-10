defmodule Opis.Server do
  @moduledoc false

  use GenServer

  alias Opis.Call
  alias Opis.TreeUtils

  defmodule State do
    @type t :: %__MODULE__{application: atom() | nil, processes: [pid()]}
    defstruct [:application, processes: []]
  end

  @ets_table :opis_calls

  ## Client

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec start_tracing() :: :ok
  @spec start_tracing(pid()) :: :ok
  def start_tracing(pid \\ self()) do
    GenServer.call(__MODULE__, {:start_tracing, pid})

    :erlang.trace(pid, true, [:call, tracer: Process.whereis(__MODULE__)])
    :erlang.trace_pattern({:_, :_, :_}, [{:_, [], [{:return_trace}]}], [:local])

    :ok
  end

  @spec stop_tracing() :: :ok
  @spec stop_tracing(pid()) :: :ok
  def stop_tracing(pid \\ self()) do
    # Ensure all traces are delivered
    :erlang.trace_delivered(pid)

    receive do
      {:trace_delivered, _, _} -> :ok
    end

    GenServer.call(__MODULE__, {:stop_tracing, pid})

    :erlang.trace_pattern({:_, :_, :_}, false, [:local])
    :erlang.trace(self(), false, [:call, tracer: Process.whereis(__MODULE__)])
  end

  @spec calls() :: [Call.t()]
  @spec calls(pid()) :: [Call.t()]
  def calls(pid \\ self()) do
    # Since `call` sends a message and waits for a reply, when this `call`
    # returns we can be assured that the server has processed all tracing
    # messages since messages are processed sequentially.
    :ok = GenServer.call(__MODULE__, :ensure_finished)

    @ets_table
    |> build_call_tree(pid)
    # Drop the last call, which is to stop Opis
    |> safe_tail()
    |> reverse_children()
  end

  defp safe_tail([]), do: []
  defp safe_tail([_ | rest]), do: rest

  defp build_call_tree(ets_table, pid) do
    {calls, _depth} =
      :ets.foldl(
        fn
          {_id, ^pid, :call, call}, {tree, depth} ->
            new_tree = TreeUtils.put_call(tree, depth, %Call{call: call})
            {new_tree, depth + 1}

          {_id, ^pid, :return, _call, value}, {tree, depth} ->
            new_depth = depth - 1
            new_tree = TreeUtils.specify_return(tree, new_depth, value)
            {new_tree, new_depth}

          _, {tree, depth} ->
            {tree, depth}
        end,
        {[], 0},
        ets_table
      )

    calls
  end

  defp reverse_children(calls) do
    calls
    |> Enum.map(fn call ->
      TreeUtils.tree_map(call, :children, fn c ->
        Map.update!(c, :children, &Enum.reverse/1)
      end)
    end)
    |> Enum.reverse()
  end

  @spec clear() :: :ok
  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  @spec clear(pid()) :: :ok
  def clear(pid) do
    GenServer.call(__MODULE__, {:clear, pid})
  end

  ## Server

  def init(_opts) do
    @ets_table = :ets.new(:opis_calls, [:named_table, :ordered_set])
    {:ok, %State{}}
  end

  def handle_info({:trace, pid, :call, call}, state) do
    if pid in state.processes do
      :ets.insert(@ets_table, {generate_id(@ets_table), pid, :call, call})
    end

    {:noreply, state}
  end

  def handle_info({:trace, pid, :return_from, call, value}, state) do
    if pid in state.processes do
      :ets.insert(@ets_table, {generate_id(@ets_table), pid, :return, call, value})
    end

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

  def handle_call(:ensure_finished, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    :ets.delete_all_objects(@ets_table)
    {:reply, :ok, state}
  end

  def handle_call({:clear, pid}, _from, state) do
    :ets.match_delete(@ets_table, {:_, pid, :call, :_})
    :ets.match_delete(@ets_table, {:_, pid, :return, :_, :_})

    {:reply, :ok, state}
  end
end
