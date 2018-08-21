defmodule Bittorrent.MixProject do
  use Mix.Project

  def project do
    [
      app: :bittorrent,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {Bittorrent.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bento, "~> 0.9"},
      {:httpoison, "~> 1.0"},
      {:bit_field_set, "~> 1.2.0"},
      {:inet_cidr, "~> 1.0.0"}
    ]
  end
end
