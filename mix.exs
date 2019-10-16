defmodule EvictionOperator.MixProject do
  use Mix.Project

  def project do
    [
      app: :eviction_operator,
      version: "0.1.1",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {EvictionOperator.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bonny, "~> 0.4.0-rc3"},
      {:notion, "~> 0.2"},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false}
    ]
  end
end
