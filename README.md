# RruleCodec

> This is based upon the [exdateutils](https://hex.pm/packages/exdateutil) package. However it has been adapted to our uses.
> Thank you to the team at [flickswitch](https://hex.pm/users/flickswitch-engineering)

**Description**
Rrule parsing and utils based on rust nif

- https://docs.rs/rrule/latest/rrule/index.html
- https://github.com/fmeringdal/rust-rrule

Only does this for now: RruleCodec.Rrule.next("DTSTART;TZID=Etc/UTC:20191220T020000\nRRULE:FREQ=MONTHLY;BYMONTHDAY=28,29,30,31;BYSETPOS=-1", 10)
## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `rrule_codec` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rrule_codec, github: "https://github.com/Marketcircle/rrule_codec", tag: "v0.1.6"}
  ]
end
```

