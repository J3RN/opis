defmodule Opis.MixProject do
  use Mix.Project

  @source_url "https://github.com/J3RN/opis"

  def project do
    [
      app: :opis,
      version: "0.2.0",
      source_url: @source_url,
      elixir: "~> 1.15",
      package: [
        licenses: ["MIT"],
        links: %{source: @source_url}
      ],
      deps: deps(),
      docs: docs()
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
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false, warn_if_outdated: true}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
