defmodule OpisTest do
  use ExUnit.Case, async: false
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
    on_exit(fn -> Opis.clear() end)
  end

  test "returns a call tree for a single function invocation" do
    Opis.manalyze(Example.a(true, false), :opis)

    result = Opis.calls()

    assert [
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
             },
             _stop_call
           ] = result
  end

  test "returns two call trees for two function invocations" do
    Opis.manalyze(Example.b(true) && Example.e(false), :opis)

    result = Opis.calls()

    assert [
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
             },
             _stop_call
           ] = result
  end

  describe "clear/1" do
    setup do
      Opis.manalyze(Example.e(false))

      task = Task.async(fn -> Opis.manalyze(Example.b(true)) end)
      Task.await(task)

      %{task_pid: task.pid}
    end

    test "clears data for pid" do
      assert Enum.any?(Opis.calls())

      Opis.clear(self())

      refute Enum.any?(Opis.calls())
    end

    test "clearing data for one pid does not clear data for others", %{task_pid: task_pid} do
      assert Enum.any?(Opis.calls(task_pid))

      Opis.clear(self())

      assert Enum.any?(Opis.calls(task_pid))
    end
  end

  describe "clear/0" do
    setup do
      Opis.manalyze(Example.e(false))

      task = Task.async(fn -> Opis.manalyze(Example.b(true)) end)
      Task.await(task)

      %{task_pid: task.pid}
    end

    test "clears data for all pids", %{task_pid: task_pid} do
      assert Enum.any?(Opis.calls())
      assert Enum.any?(Opis.calls(task_pid))

      Opis.clear()

      refute Enum.any?(Opis.calls())
      refute Enum.any?(Opis.calls(task_pid))
    end
  end
end
