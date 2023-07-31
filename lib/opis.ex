defmodule Opis do
  @moduledoc """
  Documentation for `Opis`.
  """

  @doc """
  Trace the given process, building a call tree.

  Returns the result of the given expression.  Use `calls/1` to get the
  generated call tree.
  """
  defmacro manalyze(expr, application) do
    quote do
      Opis.Server.start_tracing(unquote(application))
      result = unquote(expr)
      Opis.Server.stop_tracing(unquote(application))

      result
    end
  end

  @doc """
  Trace the given process, building a call tree.

  Returns the result of the given expression.  Use `calls/1` to get the
  generated call tree.
  """
  def analyze(fun, application) do
    Opis.Server.start_tracing(application)
    result = fun.()
    Opis.Server.stop_tracing(application)

    result
  end

  @doc """
  Returns the call tree for the current process.
  """
  defdelegate calls(), to: Opis.Server

  @doc """
  Returns the call tree from tracing the given process.
  """
  defdelegate calls(pid), to: Opis.Server

  @doc """
  Clears the recorded traces for all processes.
  """
  defdelegate clear(), to: Opis.Server

  @doc """
  Clears the recorded traces for the given process.
  """
  defdelegate clear(pid), to: Opis.Server
end
