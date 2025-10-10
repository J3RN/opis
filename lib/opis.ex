defmodule Opis do
  @moduledoc """
  The interface for debugging through recording the parameters and return
  values in the call tree of a function.
  """

  @doc """
  Trace the given expression, building a call tree.

  Returns the result of the given expression.  Use `calls/1` to get the
  generated call tree.

  Example:

      iex> Opis.analyze(Integer.parse("12"))
      {12, ""}

  """
  defmacro analyze(expr) do
    quote do
      Opis.Server.start_tracing()
      result = unquote(expr)
      Opis.Server.stop_tracing()

      result
    end
  end

  @doc """
  Trace the given expression, then print out the resulting call tree.

  Returns the result of the given expression.

  Example:

      iex> Opis.analyze_and_print(Integer.parse("12"))
      #=> Integer.parse("12") => {12, ""}
      #=>   Integer.parse("12", 10) => {12, ""}
      #=>     Integer.count_digits("12", 10) => 2
      #=>       Integer.count_digits_nosign("12", 10, 0) => 2
      #=>         Integer.count_digits_nosign("2", 10, 1) => 2
      #=>     :erlang.split_binary("12", 2) => {"12", ""}
      #=>     :erlang.binary_to_integer("12", 10) => 12
      #=>       :erts_internal.binary_to_integer("12", 10) => 12
      {12, ""}
  """
  defmacro analyze_and_print(expr) do
    quote do
      result = Opis.analyze(unquote(expr))

      for call <- Opis.calls() do
        IO.puts(call)
      end

      result
    end
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
