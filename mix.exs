defmodule Opis.MixProject do
  use Mix.Project

  def project do
    [
      app: :opis,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Opis.Application, []}
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false}
    ]
  end
end
