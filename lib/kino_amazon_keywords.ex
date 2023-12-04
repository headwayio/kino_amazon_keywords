defimpl Kino.Render, for: KinoAmazonKeywords.KeywordsCell do
  def to_livebook(result) do
    result
    |> Kino.DataTable.new(name: "Results")
    |> Kino.Render.to_livebook()
  end
end
