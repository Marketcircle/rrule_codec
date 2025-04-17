defmodule ExDateUtil.Rrule do

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
    :freq,
    :interval,
    :count,
    :until,
    :week_start,
    :by_set_pos,
    :by_month,
    :by_month_day,
    :by_year_day,
    :by_week_no,
    :by_weekday,
    :by_hour,
    :by_minute,
    :by_second
  ]

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

  def from_string(rrule_string) when is_binary(rrule_string) do
    rrule_string
    |> ExDateUtil.Rrule.Api.string_to_rrule()
    |> tuple_wrap()
  end

  def to_string(%__MODULE__{} = rrule) do
    rrule
    |> ExDateUtil.Rrule.Api.rrule_to_string()
    |> tuple_wrap()
  end

  def validate(%__MODULE__{} = rrule, dt_start) do
    rrule
    |> ExDateUtil.Rrule.Api.validate_rrule(dt_start)
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
