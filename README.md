# Opis

A tool for debugging through recording the parameters and return values in the call tree of a function.

## Usage

Opis allows you to analyze all calls that an expression makes:

```elixir
Opis.analyze(MyApp.do_thing())
```

To retrieve this data, use `calls/0`:

```elixir
Opis.calls()
```

This will return a call tree, something like this:

```elixir
[
  %Opis.Call{call: {MyApp, :do_thing, []}, return: {:ok, :success}, children: [
    %Opis.Call{call: {MyApp.Thing.do_thing, []}, return: {:ok, :success}, children: [
      # etc
    ]}
  ]}
]
```

`to_string` is implemented for the `Opis.Call` struct, so you can use `IO.puts` to view the calls in a more friendly format, e.g.

```
MyApp.do_thing() => {:ok, :success}
  MyApp.Thing.do_thing() => {:ok, :success}
    # etc
```

These two steps can be performed in one fell swoop with `Opis.analyze_and_print`:
```
Opis.analyze_and_print(MyApp.do_thing())
# MyApp.do_thing() => {:ok, :success}
#   MyApp.Thing.do_thing() => {:ok, :success}
#     etc
{:ok, :success}
```


## Installation

The package can be installed by adding `opis` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:opis, "~> 0.2.0", only: [:dev, :test]}
  ]
end
```

The docs can be found at <https://hexdocs.pm/opis>.

## Name

One of my other libraries is named [Saturn](https://github.com/J3RN/saturn), and Saturn's consort is named Ops.  Well, I couldn't name this "Ops" now could I?  Apparently there's another spelling, "Opis," which purportedly also means "plenty" in Latin.
