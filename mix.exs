defmodule ExDateUtil.MixProject do
  use Mix.Project

  @source_url "https://github.com/Flickswitch/exdateutils"
  @version "1.0.0"

  def project do
    [
      app: :exdateutil,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
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
      {:rustler_precompiled, "~> 0.6.0"},
      {:rustler, "~> 0.25.0", optional: true}
    ]
  end

  defp package do
    [
      description: "Rrule parsing",
      maintainers: ["Flickswitch engineering"],
      licenses: ["MIT"],
      files: ~w(lib rrule .formatter.exs README* LICENSE* mix.exs checksum-*.exs),
      links: %{"GitHub" => @source_url}
    ]
  end

  defp aliases do
    [
      fmt: [
        "format",
        "cmd cargo fmt --manifest-path native/io/Cargo.toml"
      ],
      test: [fn _ -> System.put_env("MJML_BUILD", "true") end, "test"]
    ]
  end
end
