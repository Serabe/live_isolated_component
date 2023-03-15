defmodule TestApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :test_app,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      preferred_cli_env: [
        "test.watch": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {TestApp.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    "PHOENIX_VERSION"
    |> System.get_env()
    |> IO.inspect(label: "PHOENIX VERSION")
    "PHOENIX_LIVE_VIEW_VERSION"
    |> System.get_env()
    |> IO.inspect(label: "PHOENIX LIVE VIEW VERSION")

    [
      {:live_isolated_component, path: "../."},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:phoenix, "~> #{System.get_env("PHOENIX_VERSION", "1.6.0")}"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, System.get_env("PHOENIX_LIVE_VIEW_VERSION", "~> 1.18.17")},
      {:floki, ">= 0.30.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get"]
    ]
  end
end
