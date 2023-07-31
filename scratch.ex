{:ok, pid} = Agent.start_link(fn -> "hello" end)

:erlang.trace(pid, true, [:call])
:erlang.trace_pattern({:_, :_, :_}, [], [:local])

Agent.update(pid, &String.split(&1, "l"))
