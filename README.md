# ExDateUtil

**Description**
Rrule parsing and utils based on rust nif

- https://docs.rs/rrule/latest/rrule/index.html
- https://github.com/fmeringdal/rust-rrule

Only does this for now: ExDateUtil.Rrule.next("DTSTART;TZID=Etc/UTC:20191220T020000\nRRULE:FREQ=MONTHLY;BYMONTHDAY=28,29,30,31;BYSETPOS=-1", 10)
## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ExDateUtil` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ExDateUtil, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ExDateUtil>.

