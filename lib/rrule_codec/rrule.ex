defmodule RruleCodec.Rrule do

  ### TODO FIX DOCTESTS

  @moduledoc """
  Provides a high-level interface for working with RFC 5545 recurrence rules (RRULEs).

  This module offers a convenient Elixir API for creating, parsing, and validating
  recurrence rules as defined in the iCalendar RFC 5545 specification. It serves
  as a user-friendly wrapper around the lower-level `RruleCodec.Rrule.Api` module,
  which in turn calls optimized Rust NIFs.

  ## Key features

  - Create recurrence rules with a simple keyword-based API
  - Parse RRULE strings into structured Elixir structs
  - Convert structured Elixir structs back to RRULE strings
  - Validate RRULEs against start dates

  ## Example usage

      # Create a weekly recurrence rule
      rrule = RruleCodec.Rrule.build(:weekly, interval: 2, by_weekday: ["MO", "WE", "FR"])

      # Validate it against a start date
      RruleCodec.Rrule.validate(rrule, "2023-01-01T09:00:00Z")
      # => :ok

      # Convert to string format
      {:ok, rrule_string} = RruleCodec.Rrule.to_string(rrule)
      # => {:ok, "FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,FR"}

      # Parse from string format
      {:ok, parsed_rrule} = RruleCodec.Rrule.from_string("FREQ=DAILY;COUNT=10")
      # => {:ok, %RruleCodec.Rrule{freq: "Daily", interval: 1, count: 10, ...}}
  """


  @type n_weekday :: String.t() | {integer(), String.t()}

  @type t :: %__MODULE__{
    freq: String.t(),
    interval: integer(),
    count: integer() | nil,
    until: DateTime.t() | nil,
    week_start: String.t(),
    by_set_pos: [integer()],
    by_month: [integer()],
    by_month_day: [integer()],
    by_year_day: [integer()],
    by_week_no: [integer()],
    by_weekday: [n_weekday()],
    by_hour: [integer()],
    by_minute: [integer()],
    by_second: [integer()]
  }

  defstruct [
    freq: nil,
    interval: 1,
    count: nil,
    until: nil,
    week_start: "Mon",
    by_set_pos: [],
    by_month: [],
    by_month_day: [],
    by_year_day: [],
    by_week_no: [],
    by_weekday: [],
    by_hour: [],
    by_minute: [],
    by_second: []
  ]


  @doc """
  Creates a new recurrence rule struct with the specified frequency and options.

  ## Parameters

    * `freq` - An atom representing the frequency (:secondly, :minutely, :hourly, :daily, :weekly, :monthly, :yearly)
    * `opts` - A keyword list of recurrence rule options:
      * `:interval` - How often the recurrence repeats (e.g., every 2 days), defaults to 1
      * `:count` - The number of occurrences (optional)
      * `:until` - The end date of the recurrence as a DateTime (optional)
      * `:week_start` - The day of the week that starts the week (e.g., "Mon"), defaults to "Mon"
      * `:by_set_pos` - List of positions within the set of recurrence instances (defaults to [])
      * `:by_month` - List of months to include (defaults to [])
      * `:by_month_day` - List of days of the month to include (defaults to [])
      * `:by_year_day` - List of days of the year to include (defaults to [])
      * `:by_week_no` - List of week numbers to include (defaults to [])
      * `:by_weekday` - List of weekdays to include, either as strings ("MO") or tuples with positions ({1, "MO"}) (defaults to [])
      * `:by_hour` - List of hours to include (defaults to [])
      * `:by_minute` - List of minutes to include (defaults to [])
      * `:by_second` - List of seconds to include (defaults to [])

  ## Returns

    * `%RruleCodec.Rrule{}` - A struct representing the recurrence rule

  ## Examples

      # Daily recurrence
      iex> RruleCodec.Rrule.build(:daily, interval: 1)
      %RruleCodec.Rrule{freq: "Daily", interval: 1, week_start: "Mon", by_set_pos: [], by_month: [], by_month_day: [], by_year_day: [], by_week_no: [], by_weekday: [], by_hour: [], by_minute: [], by_second: []}

      # Weekly recurrence on Monday, Wednesday, and Friday
      iex> RruleCodec.Rrule.build(:weekly, by_weekday: ["MO", "WE", "FR"])
      %RruleCodec.Rrule{freq: "Weekly", interval: 1, week_start: "Mon", by_set_pos: [], by_month: [], by_month_day: [], by_year_day: [], by_week_no: [], by_weekday: ["MO", "WE", "FR"], by_hour: [], by_minute: [], by_second: []}

      # Monthly recurrence with count limit
      iex> RruleCodec.Rrule.build(:monthly, count: 10)
      %RruleCodec.Rrule{freq: "Monthly", interval: 1, count: 10, week_start: "Mon", by_set_pos: [], by_month: [], by_month_day: [], by_year_day: [], by_week_no: [], by_weekday: [], by_hour: [], by_minute: [], by_second: []}

  ## Raises

    * `ArgumentError` - If an invalid frequency is provided
  """
  def build(freq, opts) when is_atom(freq) do
      %__MODULE__{
        freq: parse_frequency!(freq),
        interval: Keyword.get(opts, :interval, 1),
        count: Keyword.get(opts, :count),
        until: Keyword.get(opts, :until),
        week_start: Keyword.get(opts, :week_start, "Mon"),
        by_set_pos: Keyword.get(opts, :by_set_pos, []),
        by_month: Keyword.get(opts, :by_month, []),
        by_month_day: Keyword.get(opts, :by_month_day, []),
        by_year_day: Keyword.get(opts, :by_year_day, []),
        by_week_no: Keyword.get(opts, :by_week_no, []),
        by_weekday: Keyword.get(opts, :by_weekday, []),
        by_hour: Keyword.get(opts, :by_hour, []),
        by_minute: Keyword.get(opts, :by_minute, []),
        by_second: Keyword.get(opts, :by_second, [])
      }
  end

  @doc """
  Parses an RFC 5545 RRULE string into a structured `RruleCodec.Rrule` struct.

  This function takes a string representation of a recurrence rule (RRULE) as defined in RFC 5545
  and converts it into a structured Elixir struct.

  ## Parameters

    * `rrule_string` - A string containing an RFC 5545 compliant RRULE (e.g., "FREQ=DAILY;INTERVAL=2")

  ## Returns

    * `{:ok, %RruleCodec.Rrule{}}` - A structured representation of the RRULE if parsing succeeds
    * `{:error, reason}` - An error if the RRULE string is malformed or contains invalid values

  ## Examples

      iex> RruleCodec.Rrule.from_string("FREQ=DAILY;INTERVAL=2;COUNT=10")
      {:ok, %RruleCodec.Rrule{freq: "Daily", interval: 2, count: 10, week_start: "Mon", by_set_pos: [], by_month: [], by_month_day: [], by_year_day: [], by_week_no: [], by_weekday: [], by_hour: [], by_minute: [], by_second: []}}

      iex> RruleCodec.Rrule.from_string("FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR")
      {:ok, %RruleCodec.Rrule{freq: "Weekly", interval: 1, week_start: "Mon", by_set_pos: [], by_month: [], by_month_day: [], by_year_day: [], by_week_no: [], by_weekday: ["Mon", "Wed", "Fri"], by_hour: [], by_minute: [], by_second: []}}

      iex> RruleCodec.Rrule.from_string("INVALID")
      {:error, "Error parsing rrule: ParserError(InvalidParameterFormat(\\\"INVALID\\\"))"}
  """
  def from_string(rrule_string) when is_binary(rrule_string) do
    rrule_string
    |> RruleCodec.Rrule.Api.string_to_rrule()
    |> tuple_wrap()
  end

  @doc """
  Converts an `RruleCodec.Rrule` struct back into an RFC 5545 RRULE string.

  This function takes an Elixir struct that represents a recurrence rule and
  converts it back into a string representation that follows the RFC 5545 RRULE format.

  ## Parameters

    * `rrule` - An `RruleCodec.Rrule` struct containing the RRULE parameters

  ## Returns

    * `{:ok, string}` - The string representation of the RRULE if conversion succeeds
    * `{:error, reason}` - An error if the struct contains invalid values

  ## Examples

      iex> rrule = %RruleCodec.Rrule{freq: "Daily", interval: 2, count: 10}
      iex> RruleCodec.Rrule.to_string(rrule)
      {:ok, "FREQ=DAILY;COUNT=10;INTERVAL=2"}

      iex> rrule = %RruleCodec.Rrule{freq: "Weekly", interval: 1, by_weekday: ["Mon", "Wed", "Fri"]}
      iex> RruleCodec.Rrule.to_string(rrule)
      {:ok, "FREQ=WEEKLY;BYDAY=MO,WE,FR"}

      iex> rrule = %RruleCodec.Rrule{freq: "InvalidFreq", interval: 1, week_start: "Mon", by_set_pos: []}
      iex> RruleCodec.Rrule.to_string(rrule)
      {:error, "Error converting properties to rrule: {error, {:error, <term>}}"}
  """
  def to_string(%__MODULE__{} = rrule) do
    rrule
    |> RruleCodec.Rrule.Api.rrule_to_string()
    |> tuple_wrap()
  end

  @doc """
  Validates if a recurrence rule is properly formed with respect to a start date.

  This function checks if the given `RruleCodec.Rrule` struct represents a valid recurrence rule
  when combined with the provided start date. The validation includes checking if all
  rule components are consistent with each other and with the start date.

  ## Parameters

    * `rrule` - An `RruleCodec.Rrule` struct containing the RRULE parameters
    * `dt_start` - A string containing an RFC 3339 formatted date-time for the rule's start date

  ## Returns

    * `:ok` - If the RRULE is valid
    * `{:error, reason}` - An error describing why the RRULE is invalid

  ## Examples

      iex> rrule = RruleCodec.Rrule.build(:weekly, interval: 1, by_weekday: ["Mon", "Wed", "Fri"])
      iex> RruleCodec.Rrule.validate(rrule, "2023-04-01T00:00:00Z")
      :ok

      iex> rrule = RruleCodec.Rrule.build(:monthly, interval: 1,  by_month_day: [35])
      iex> RruleCodec.Rrule.validate(rrule, "2023-02-01T00:00:00Z")
      {:error, "Invalid rrule: ValidationError(InvalidFieldValueRange { field: \\\"BYMONTHDAY\\\", value: \\\"35\\\", start_idx: \\\"-31\\\", end_idx: \\\"31\\\" })"}

      iex> rrule = %RruleCodec.Rrule{freq: "Monthly", interval: 1, by_set_pos: []}
      iex> RruleCodec.Rrule.validate(rrule, "invalid-date")
      {:error, "Invalid datetime: invalid-date"}
  """
  def validate(%__MODULE__{} = rrule, dt_start) do
    rrule
    |> RruleCodec.Rrule.Api.validate_rrule(dt_start)
  end

  defp parse_frequency(as_atom) do
    case as_atom do
      :secondly -> {:ok, "Secondly"}
      :minutely -> {:ok, "Minutely"}
      :hourly -> {:ok, "Hourly"}
      :daily -> {:ok, "Daily"}
      :weekly -> {:ok, "Weekly"}
      :monthly -> {:ok, "Monthly"}
      :yearly -> {:ok, "Yearly"}
      _ -> {:error, "Invalid frequency: #{inspect(as_atom)}"}
    end
  end

  defp parse_frequency!(as_atom) do
    case parse_frequency(as_atom) do
      {:ok, frequency} -> frequency
      {:error, message} -> raise ArgumentError, message
    end
  end

  # on error rustler functions return a {:error, reason} tuple
  # on success they just return the result
  # this function wraps the result in a tuple
  defp tuple_wrap({:error, reason}) do
    {:error, reason}
  end

  defp tuple_wrap(result) do
    {:ok, result}
  end
end
