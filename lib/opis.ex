defmodule Opis do
  @moduledoc """
  Documentation for `Opis`.
  """

  defmacro analyze(do: expr) do
    quote do
      # Start our monitor
      {:ok, var!(server)} = Opis.Server.start_link()

      # Start tracing
      :erlang.trace(self(), true, [:call, tracer: var!(server)])
      :erlang.trace_pattern({:_, :_, :_}, true, [:local])

      unquote(expr)

      # Stop tracing
      :erlang.trace(self(), false, [:call, tracer: var!(server)])

      # Ensure all traces are delivered
      :erlang.trace_delivered(var!(server))

      receive do
        {:trace_delivered, _, _} -> :ok
      end

      # This is a bit weird, but it ensures that all traces have been processed
      # by the server.  When the server responds to our call, we can be assured
      # that all the trace messages have already been handled.
      :ok = GenServer.call(var!(server), :flush)
    end
  end
end
