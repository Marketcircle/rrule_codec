defmodule ExDateUtil.Rrule.Api do
  @moduledoc """
  Rrule parsing and utility functions using precompiled Rust NIF from https://github.com/fmeringdal/rust-rrule

  # Note:
  - All RRules must contain a DTSTART value, e.g. `DTSTART;TZID=Europe/London:20230326T000000Z`
  - All dates must be passed in RFC3339 format, e.g. `"2023-06-19T12:00:01+01:00"`
  """

  mix_config = Mix.Project.config()
  version = mix_config[:version]
  github_url = mix_config[:package][:links]["GitHub"]

  targets = ~w(
    aarch64-apple-darwin
    aarch64-unknown-linux-gnu
    aarch64-unknown-linux-musl
    x86_64-apple-darwin
    x86_64-unknown-linux-gnu
    x86_64-unknown-linux-musl
  )

  use RustlerPrecompiled,
    otp_app: :exdateutil,
    crate: "exdateutil_rrule",
    base_url: "#{github_url}/releases/download/v#{version}",
    force_build: System.get_env("RRULE_BUILD") in ["1", "true"],
    version: version,
    targets: targets


  def string_to_rrule(_rrule_string), do: error()

  def rrule_to_string(_rrule_struct), do: error()

  def validate_rrule(_rrule_struct, _dt_start), do: error()

  def to_rruleset(_rrule_struct, _dt_start, _rdate, _exrule, _exdate, _before_date, _after_date, _limited),
    do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
