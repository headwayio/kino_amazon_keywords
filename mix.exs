defmodule KinoKeywords.MixProject do
  use Mix.Project

  @version "0.1.14"
  @description "Collection of Super Disco smart cells for keyword management"

  def project do
    [
      app: :kino_keywords,
      description: @description,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {KinoKeywords.Application, []},
      extra_applications: [:logger, :export]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:kino, "~> 0.11.3"},
      {:req, "~> 0.4.0"},
      {:explorer, "~> 0.7.1"},
      {:kino_explorer, "~> 0.1.11"},
      {:floki, "~> 0.35.2"},
      {:mock, "~> 0.3.0", only: :test},
      {:export, "~> 0.1.1"}
    ]
  end

  defp docs do
    [
      main: "components",
      source_url: "https://github.com/headwayio/kino_keywords",
      source_ref: "v#{@version}",
      extras: []
    ]
  end
end
