defmodule OpisTest do
  use ExUnit.Case
  doctest Opis
  alias Opis.Call

  defmodule Example do
    def a(one, two), do: b(one) && d(two)
    def b(one), do: !c(one)
    def c(one), do: !one
    def d(two), do: e(two) || !f(two)
    def e(two), do: two
    def f(two), do: !two
  end

  setup do
    start_supervised!(Opis.Server)
    :ok
  end

  describe "analyze" do
    test "returns a call tree for a single function invocation" do
      Opis.analyze do
        Example.a(true, false)
      end

      {:ok, result} = Opis.calls()

      expected = [
        %Call{
          call: {Example, :a, [true, false]},
          return: false,
          children: [
            %Call{
              call: {Example, :b, [true]},
              return: true,
              children: [
                %Call{
                  call: {Example, :c, [true]},
                  return: false,
                  children: []
                }
              ]
            },
            %Call{
              call: {Example, :d, [false]},
              return: false,
              children: [
                %Call{
                  call: {Example, :e, [false]},
                  return: false,
                  children: []
                },
                %Call{
                  call: {Example, :f, [false]},
                  return: true,
                  children: []
                }
              ]
            }
          ]
        }
      ]

      assert result == expected
    end

    test "returns two call trees for two function invocations" do
      Opis.analyze do
        Example.b(true) && Example.e(false)
      end

      {:ok, result} = Opis.calls()

      expected = [
        %Call{
          call: {Example, :b, [true]},
          return: true,
          children: [
            %Call{
              call: {Example, :c, [true]},
              return: false,
              children: []
            }
          ]
        },
        %Call{
          call: {Example, :e, [false]},
          return: false,
          children: []
        }
      ]

      assert result == expected
    end
  end
end
