defmodule KinoAmazonKeywords.MixProject do
  use Mix.Project

  @version "0.1.10"
  @description "Create dataframe from popular search terms from Amazon"

  def project do
    [
      app: :kino_amazon_keywords,
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
      mod: {KinoAmazonKeywords.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:kino, "~> 0.11.3"},
      {:req, "~> 0.4.0"},
      {:explorer, "~> 0.7.1"},
      {:kino_explorer, "~> 0.1.11"},
      {:floki, "~> 0.35.2"}
    ]
  end

  defp docs do
    [
      main: "components",
      source_url: "https://github.com/headwayio/kino_amazon_keywords",
      source_ref: "v#{@version}",
      extras: []
    ]
  end
end
