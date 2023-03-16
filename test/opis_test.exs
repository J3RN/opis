defmodule OpisTest do
  use ExUnit.Case
  doctest Opis

  test "greets the world" do
    Opis.analyze do
      String.split("hello", "l")
    end
  end
end
