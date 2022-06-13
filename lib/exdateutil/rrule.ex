defmodule ExDateUtil.Rrule do
  use Rustler, otp_app: :ExDateUtil, crate: :ExDateUtil_rrule

  def next(rrule, limit), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
