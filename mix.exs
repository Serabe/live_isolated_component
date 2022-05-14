defmodule LiveIsolatedComponent.MixProject do
  use Mix.Project

  def project do
    [
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        list_unused_filters: true,
        plt_file: {:no_warn, "live_isolated_component.plt"}
      ],
      app: :live_isolated_component,
      version: "0.1.0",
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.6.4", only: :dev, runtime: false},
      {:mix_test_watch, "~> 1.1.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.28.4", only: :dev, runtime: false},
      {:phoenix, "~> 1.6.8"},
      {:phoenix_live_view, "~> 0.17.9"}
    ]
  end
end
