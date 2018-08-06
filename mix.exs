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
      extra_applications: [:logger],
      mod: {Bittorrent.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bento, "~> 0.9"},
      {:httpoison, "~> 1.0"}
    ]
  end
end
