defmodule ExDateUtil.Rrule.Api do
  @moduledoc """
  Rrule parsing and utility functions using precompiled Rust NIF from https://github.com/fmeringdal/rust-rrule

  This module provides functions for working with RFC 5545 recurrence rules (RRULEs).
  It allows parsing RRULE strings into structured Elixir types, converting structured
  Elixir types into RRULE strings, and validating RRULEs against start dates.

  ## Note:
  - All RRules must contain a DTSTART value, e.g. `DTSTART;TZID=Europe/London:20230326T000000Z`
  - All dates must be passed in RFC3339 format, e.g. `"2023-06-19T12:00:01+01:00"`

  ## Examples

      # Parse an RRULE string into a structured Elixir type
      iex> rrule = ExDateUtil.Rrule.Api.string_to_rrule("FREQ=DAILY;INTERVAL=2;COUNT=10")
      iex> rrule.freq
      :daily
      iex> rrule.interval
      2
      iex> rrule.count
      10

      # Convert an Elixir struct back to an RRULE string
      iex> rrule = %ExDateUtil.Rrule{freq: :weekly, interval: 1, by_weekday: ["MO", "WE", "FR"]}
      iex> ExDateUtil.Rrule.Api.rrule_to_string(rrule)
      "FREQ=WEEKLY;BYDAY=MO,WE,FR"

      # Validate an RRULE against a start date
      iex> rrule = %ExDateUtil.Rrule{freq: :monthly, interval: 1, by_month_day: [24]}
      iex> ExDateUtil.Rrule.Api.validate_rrule(rrule, "2023-04-01T00:00:00Z")
      :ok

      iex> rrule = %ExDateUtil.Rrule{freq: :monthly, interval: 1, by_month_day: [32]}
      iex> ExDateUtil.Rrule.Api.validate_rrule(rrule, "2023-02-01T00:00:00Z")
      {:error, "Error validating rrule: February doesn't have 32 days"}
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

  @doc """
  Parses an RFC 5545 RRULE string into a structured `ExDateUtil.Rrule` struct.

  This function takes a string representation of a recurrence rule (RRULE) as defined in RFC 5545
  and converts it into a structured Elixir struct that can be used in your application.

  ## Parameters

    * `rrule_string` - A string containing an RFC 5545 compliant RRULE (e.g., "FREQ=DAILY;INTERVAL=2")

  ## Returns

    * `{:ok, %ExDateUtil.Rrule{}}` - A structured representation of the RRULE if parsing succeeds
    * `{:error, reason}` - An error if the RRULE string is malformed or contains invalid values

  ## Examples

      iex> ExDateUtil.Rrule.Api.string_to_rrule("FREQ=DAILY;INTERVAL=2;COUNT=10")
      {:ok, %ExDateUtil.Rrule{freq: "Daily", interval: 2, count: 10}}

      iex> ExDateUtil.Rrule.Api.string_to_rrule("FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR")
      {:ok, %ExDateUtil.Rrule{freq: "Weekly", interval: 1, by_weekday: ["MO", "WE", "FR"]}}

      iex> ExDateUtil.Rrule.Api.string_to_rrule("INVALID")
      {:error, "Error parsing rrule: Invalid format"}
  """
  def string_to_rrule(_rrule_string), do: error()

  @doc """
  Converts an `ExDateUtil.Rrule` struct back into an RFC 5545 RRULE string.

  This function takes an Elixir struct that represents a recurrence rule and
  converts it back into a string representation that follows the RFC 5545 RRULE format.

  ## Parameters

    * `rrule_struct` - An `ExDateUtil.Rrule` struct containing the RRULE parameters

  ## Returns

    * `{:ok, string}` - The string representation of the RRULE if conversion succeeds
    * `{:error, reason}` - An error if the struct contains invalid values

  ## Examples

      iex> rrule = %ExDateUtil.Rrule{freq: "Daily", interval: 2, count: 10}
      iex> ExDateUtil.Rrule.Api.rrule_to_string(rrule)
      {:ok, "FREQ=DAILY;INTERVAL=2;COUNT=10"}

      iex> rrule = %ExDateUtil.Rrule{freq: "Weekly", interval: 1, by_weekday: ["MO", "WE", "FR"]}
      iex> ExDateUtil.Rrule.Api.rrule_to_string(rrule)
      {:ok, "FREQ=WEEKLY;BYDAY=MO,WE,FR"}

      iex> rrule = %ExDateUtil.Rrule{freq: "InvalidFreq", interval: 1}
      iex> ExDateUtil.Rrule.Api.rrule_to_string(rrule)
      {:error, "Error converting properties to rrule: Invalid frequency: InvalidFreq"}
  """
  def rrule_to_string(_rrule_struct), do: error()

  @doc """
  Validates if a recurrence rule is properly formed with respect to a start date.

  This function checks if the given `ExDateUtil.Rrule` struct represents a valid recurrence rule
  when combined with the provided start date. The validation includes checking if all
  rule components are consistent with each other and with the start date.

  ## Parameters

    * `rrule_struct` - An `ExDateUtil.Rrule` struct containing the RRULE parameters
    * `dt_start` - A string containing an RFC 3339 formatted date-time for the rule's start date

  ## Returns

    * `:ok` - If the RRULE is valid
    * `{:error, reason}` - An error describing why the RRULE is invalid

  ## Examples

      iex> rrule = %ExDateUtil.Rrule{freq: "Monthly", interval: 1, by_month_day: [22]}
      iex> ExDateUtil.Rrule.Api.validate_rrule(rrule, "2023-04-01T00:00:00Z")
      :ok

      iex> rrule = %ExDateUtil.Rrule{freq: "Monthly", interval: 1, by_month_day: [-1]}
      iex> ExDateUtil.Rrule.Api.validate_rrule(rrule, "2023-02-01T00:00:00Z")
      {:error, "Error validating rrule: February doesn't have -1 days"}

      iex> rrule = %ExDateUtil.Rrule{freq: "Monthly", interval: 1}
      iex> ExDateUtil.Rrule.Api.validate_rrule(rrule, "invalid-date")
      {:error, "Invalid datetime: invalid-date"}
  """
  def validate_rrule(_rrule_struct, _dt_start), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
