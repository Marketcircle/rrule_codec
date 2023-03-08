defmodule ExDateUtil.Rrule do
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


  # use Rustler, otp_app: :exdateutil, crate: :exdateutil_rrule

  def next(rrule, limit), do: error()
  def between(rrule, start_date, end_date, inc), do: error()
  def just_before(rrule, before_date, inc), do: error()
  def just_after(rrule, after_date, inc), do: error()
  def properties(rrule), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
