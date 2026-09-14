defmodule Companion.MixProject do
  use Mix.Project

  def project do
    [
      app: :companion,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Companion.Application, []}
    ]
  end

  defp deps do
    [
      {:circuits_uart, "~> 1.6.0"},
      {:deps_nix, "~> 2.5.0"},
      {:box, git: "https://github.com/nicklayb/box_ex.git", tag: "0.19.0"},
      {:mox, "~> 1.3.0", only: :test},
      {:ivhs_broker, git: "https://github.com/nicklayb/ivhs_broker.git", runtime: false},
      {:mqttx, "~> 0.11.0"},
      {:thousand_island, "~> 1.4"}
    ]
  end

  defp aliases do
    [
      "deps.get": ["deps.get", "deps.nix"],
      "deps.update": ["deps.update", "deps.nix"]
    ]
  end
end
