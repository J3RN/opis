defmodule Opis do
  @moduledoc """
  Documentation for `Opis`.
  """

  defmacro analyze(do: expr) do
    quote do
      {:ok, var!(server)} = Opis.Server.start_link()
      :erlang.trace(self(), true, [:call, tracer: var!(server)])
      :erlang.trace_pattern({:_, :_, :_}, true, [:local])

      unquote(expr)

      :erlang.trace_delivered(var!(server))

      receive do
        {:trace_delivered, _, _} -> :ok
      end

      :ok = GenServer.call(var!(server), :flush)

      :erlang.trace(self(), false, [:call, tracer: var!(server)])
    end
  end
end
