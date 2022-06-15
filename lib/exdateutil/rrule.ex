defmodule ExDateUtil.Rrule do
  use Rustler, otp_app: :exdateutil, crate: :exdateutil_rrule

  def next(rrule, limit), do: error()
  def between(rrule, start_date, end_date, inc), do: error()
  def just_before(rrule, before_date, inc), do: error()
  def just_after(rrule, after_date, inc), do: error()
  def properties(rrule), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
