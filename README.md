# Opis

A tool for debugging through recording the parameters and returns values in the call tree of a function.

⚠️ Opis isn't working quite right for OTP-27 due to the tracing changes.  A fix is in development.⚠️

## Usage

First, you'll need to start the Opis process:

```elixir
Opis.Server.start_link()
```

With that out of the way, now you can analyze a code block:

```elixir
Opis.manalyze do
  MyApp.do_thing()
end
```
<small>The name `manalyze` is short for "macro analyze".  Better name suggestions are welcome!</small>

This will record all the internal workings of the given code block.  To retrieve this data, use `calls/0`:

```elixir
Opis.calls()
```

This will return a call tree, something like this:

```elixir
[
  %Opis.Call{call: {MyApp, :do_thing, []}, return: {:ok, :success}, children: [
    %Opis.Call{call: {MyApp.Thing.do_thing, []}, return: {:ok, success}, children: [
      # etc
    ]}
  ]}
]
```

`to_string` is implemented for the `Opis.Call` struct, so you can use `IO.puts` to view the calls in a more friendly format, e.g.

```
MyApp.do_thing() => {:ok, :success}
  MyApp.Thing.do_thing() => {:ok, success}
    # etc
```

There is a non-macro function to perform the equivalent work, named `analyze`:
```elixir
Opis.analyze(fn -> MyApp.do_thing() end)
```

## Installation

The package can be installed by adding `opis` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:opis, "~> 0.1.0", only: [:dev, :test]}
  ]
end
```

The docs can be found at <https://hexdocs.pm/opis>.

## Name

One of my other libraries is named [Saturn](https://github.com/instinctscience/saturn), and Saturn's consort is named Ops.  Well, I couldn't name this "Ops" now could I?  Apparently there's another spelling, "Opis," which purportedly also means "plenty" in Latin.
