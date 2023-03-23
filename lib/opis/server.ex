defmodule Opis.Server do
  @moduledoc false

  use GenServer

  alias Opis.Call

  defmodule State do
    @type t :: %__MODULE__{calls: %Call{}, path: [term()]}
    defstruct calls: %Call{}, path: []
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
    :erlang.trace_pattern({:_, :_, :_}, false, [:local])
    :erlang.trace(pid, false, [:call, tracer: Process.whereis(__MODULE__)])

    # Ensure all traces are delivered
    :erlang.trace_delivered(Process.whereis(__MODULE__))

    receive do
      {:trace_delivered, _, _} -> :ok
    end
  end

  def calls(pid \\ self()) do
    # As a side effect, using `call` here ensures that the server has processed
    # all tracing messages since messages are processed sequentially.
    with {:ok, calls} <- GenServer.call(__MODULE__, {:calls, pid}) do
      {:ok, calls.children}
    end
  end

  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  def clear(pid) do
    GenServer.call(__MODULE__, {:clear, pid})
  end

  ## Server

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_info({:trace, pid, :call, call}, state) do
    new_state =
      case Map.fetch(state, pid) do
        {:ok, %State{calls: calls, path: path} = substate} ->
          {new_index, new_calls} = put_call(calls, Enum.reverse(path), %Call{call: call})
          new_substate = %State{substate | path: [new_index | path], calls: new_calls}
          %{state | pid => new_substate}

        :error ->
          state
      end

    {:noreply, new_state}
  end

  def handle_info({:trace, pid, :return_from, _call, value}, state) do
    new_state =
      case Map.fetch(state, pid) do
        {:ok, %State{calls: calls, path: [_ | newpath] = path} = substate} ->
          new_calls = update_call(calls, Enum.reverse(path), &%Call{&1 | return: value})
          new_substate = %State{substate | calls: new_calls, path: newpath}
          %{state | pid => new_substate}

        :error ->
          state
      end

    {:noreply, new_state}
  end

  def handle_call({:start_tracing, pid}, _from, state) do
    {:reply, :ok, Map.put(state, pid, %State{})}
  end

  def handle_call({:calls, pid}, _from, state) do
    result =
      case Map.fetch(state, pid) do
        {:ok, calls} -> {:ok, calls.calls}
        :error -> {:error, :process_not_traced}
      end

    {:reply, result, state}
  end

  def handle_call(:clear, _from, _state) do
    {:reply, :ok, %{}}
  end

  def handle_call({:clear, pid}, _from, state) do
    {:reply, :ok, Map.delete(state, pid)}
  end

  defp put_call(calls, [], call) when is_list(calls) do
    {length(calls), calls ++ [call]}
  end

  defp put_call(leaf_call, [], call) when is_struct(leaf_call, Call) do
    {new_index, updated_children} = put_call(leaf_call.children, [], call)
    {new_index, %Call{leaf_call | children: updated_children}}
  end

  defp put_call(calls, [h | rest], call) when is_list(calls) do
    {new_index, updated_call} = put_call(Enum.at(calls, h), rest, call)
    {new_index, List.replace_at(calls, h, updated_call)}
  end

  defp put_call(tree_call, path, call) when is_struct(tree_call, Call) do
    {new_index, updated_children} = put_call(tree_call.children, path, call)
    {new_index, %Call{tree_call | children: updated_children}}
  end

  defp update_call(tree, [], update_fn) do
    update_fn.(tree)
  end

  defp update_call(tree, [h | rest], update_fn) do
    updated_children = List.update_at(tree.children, h, &update_call(&1, rest, update_fn))
    %Call{tree | children: updated_children}
  end
end
