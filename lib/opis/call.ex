defmodule Opis.Call do
  @type t :: %__MODULE__{call: {module(), atom(), [term()]}, children: [t()], return: term()}
  defstruct [:call, :return, children: []]

  defimpl String.Chars do
    def to_string(%Opis.Call{call: {module, function, args}, return: return, children: children}) do
      child_strs =
        if children != [] do
          "\n" <>
            (Enum.map_join(children, "\n", &Kernel.to_string/1)
             |> String.split("\n")
             |> Enum.map(&("  " <> &1))
             |> Enum.join("\n"))
        else
          ""
        end

      "#{inspect(module)}.#{Kernel.to_string(function)}(#{Enum.map_join(args, ", ", &inspect/1)}) => #{inspect(return)}#{child_strs}"
    end
  end
end
