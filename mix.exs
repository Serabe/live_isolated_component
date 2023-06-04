defmodule LiveIsolatedComponent.MixProject do
  use Mix.Project

  @version "0.6.3"

  def project do
    [
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        list_unused_filters: true,
        plt_core_path: "priv/plts",
        plt_file: {:no_warn, "priv/plts/live_isolated_component.plt"}
      ],
      app: :live_isolated_component,
      package: package(),
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def package do
    [
      maintainers: ["Sergio Arbeo"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Serabe/live_isolated_component"},
      files: ~w(lib LICENSE.txt mix.exs README.md),
      description: "Simple library to test LV components live in isolation"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.6.4", only: :dev, runtime: false},
      {:mix_test_watch, "~> 1.1.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.28.4", only: :dev, runtime: false},
      {:phoenix, "~> 1.6.0 or ~> 1.7.0"},
      {:phoenix_live_view, "~> 0.18.0 or ~> 0.19.0"}
    ]
  end
end
