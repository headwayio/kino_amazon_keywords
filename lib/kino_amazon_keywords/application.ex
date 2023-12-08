defmodule KinoAmazonKeywords.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Kino.SmartCell.register(KinoAmazonKeywords.KeywordsCell)
    Kino.SmartCell.register(KinoAmazonKeywords.ProductsCell)

    children = []
    opts = [strategy: :one_for_one, name: KinoAmazonKeywords.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
