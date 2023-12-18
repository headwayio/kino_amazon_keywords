defmodule KinoKeywords.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Kino.SmartCell.register(KinoKeywords.KeywordsCell)
    Kino.SmartCell.register(KinoKeywords.ProductsCell)
    Kino.SmartCell.register(KinoKeywords.KeywordsByASINCell)
    Kino.SmartCell.register(KinoKeywords.KeywordRootAnalysisCell)

    children = []
    opts = [strategy: :one_for_one, name: KinoKeywords.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
