defmodule RruleCodec.MixProject do
  use Mix.Project

  @source_url "https://github.com/team-alebmic/rrule_codec"
  @version "0.1.2"

  def project do
    [
      app: :rrule_codec,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:rustler_precompiled, "~> 0.8.2"},
      {:rustler, "~> 0.36.1", optional: true}
    ]
  end

  defp package do
    [
      description: "Rrule codec",
      maintainers: ["Marketcircle"],
      licenses: ["MIT"],
      files: ~w(lib native .formatter.exs README* LICENSE* mix.exs checksum-*.exs),
      links: %{"GitHub" => @source_url}
    ]
  end

  defp aliases do
    [
      fmt: [
        "format",
        "cmd cargo fmt --manifest-path native/rrule_codec_rs/Cargo.toml"
      ]
    ]
  end
end
