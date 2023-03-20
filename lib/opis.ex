defmodule Opis do
  @moduledoc """
  Documentation for `Opis`.
  """

  @doc """
  Trace the given process, building a call tree.

  Returns the result of the given expression.  Use `calls/1` to get the
  generated call tree.
  """
  def analyze(fun) do
    Opis.Server.start_tracing()
    result = fun.()
    Opis.Server.stop_tracing()

    result
  end

  @doc """
  Returns the call tree from tracing the given process.
  """
  defdelegate calls(), to: Opis.Server
  defdelegate calls(pid), to: Opis.Server

  @doc """
  Clears the recorded traces for all processes.
  """
  defdelegate clear(), to: Opis.Server

  @doc """
  Clears the recorded traces for the current process.
  """
  defdelegate clear(pid), to: Opis.Server
end
