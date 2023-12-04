defmodule KinoAmazonKeywords.KeywordsCell do
  @moduledoc """
  Documentation for `KinoAmazonKeywords`.
  """
  use Kino.JS
  use Kino.JS.Live
  use Kino.SmartCell, name: "Amazon Keywords"

  @impl true
  def init(attrs, ctx) do
    {:ok, assign(ctx, keywords: attrs[:keywords])}
  end

  @impl true
  def handle_connect(ctx) do
    {:ok, %{keywords: ctx.assigns.keywords}, ctx}
  end

  @impl true
  def to_attrs(ctx) do
    %{keywords: ctx.assigns.keywords}
    |> Kino.SmartCell.quoted_to_string()
  end

  @impl true
  def to_source(attrs) do
    attrs
    |> to_quoted()
    |> Kino.SmartCell.quoted_to_string()
  end

  def update(kino, keywords) do
    Kino.JS.Live.cast(kino, {:update, keywords})
  end

  defp to_quoted(_attrs) do
    quote do
      keyword_input = Kino.Input.text("Keyword", default: "")
      form = Kino.Control.form([keyword: keyword_input], submit: "Submit")
      keywords = ["foo"]

      Kino.inspect("something happened")

      frame = Kino.Frame.new()

      Kino.listen(form, fn %{data: %{keyword: keyword}} ->
        if keyword do
          Kino.Frame.render(frame, Kino.Text.new("Running..."))

          keywords = KinoAmazonKeywords.Keywords.fetch(keyword)

          Kino.Frame.render(frame, Kino.Tree.new(keywords))
        end
      end)

      Kino.Layout.grid([form, frame], boxed: true, gap: 16)
    end
  end

  @impl true
  def handle_cast({:update, keywords}, ctx) do
    # broadcast_event(ctx, "update", keywords)
    {:noreply, assign(ctx, keywords: keywords)}
  end

  asset "main.js" do
    """
      export function init(ctx, payload) {
        ctx.importCSS("main.css");
      }
    """
  end

  asset "main.css" do
    """
    """
  end
end
