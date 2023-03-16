defmodule Opis do
  @moduledoc """
  Documentation for `Opis`.
  """

  @doc """
  Trace the given process, building a call tree.

  Returns the result of the given expression.  Use `calls/1` to get the
  generated call tree.
  """
  defmacro analyze(do: expr) do
    quote do
      Opis.Server.start_tracing()
      result = unquote(expr)
      Opis.Server.stop_tracing()

      result
    end
  end

  @doc """
  Returns the call tree from tracing the given process.
  """
  defdelegate calls(), to: Opis.Server
  defdelegate calls(pid), to: Opis.Server
end
