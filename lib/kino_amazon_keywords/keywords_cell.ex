defmodule KinoAmazonKeywords.KeywordsCell do
  @moduledoc false
  use Kino.JS, assets_path: "lib/assets"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Amazon Keywords"

  def new do
    Kino.JS.new(__MODULE__, %{fields: %{}})
  end

  @impl true
  def init(attrs, ctx) do
    fields = %{
      "keyword" => attrs["keyword"]
    }

    ctx = assign(ctx, fields: fields)
    {:ok, ctx, reevaluate_on_change: true}
  end

  @impl true
  def handle_connect(ctx) do
    {:ok, %{fields: ctx.assigns[:fields]}, ctx}
  end

  @impl true
  def to_attrs(ctx) do
    ctx.assigns.fields
  end

  @impl true
  def to_source(attrs) do
    attrs
    |> to_quoted()
    |> Kino.SmartCell.quoted_to_string()
  end

  @impl true
  def handle_event("update_keyword", value, ctx) do
    ctx = update(ctx, :fields, &Map.merge(&1, %{"keyword" => value}))
    {:noreply, ctx}
  end

  @impl true
  def handle_event("submit", _, ctx) do
    ctx = update(ctx, :fields, &Map.merge(&1, ctx.assigns.fields))
    {:noreply, ctx}
  end

  @impl true
  def handle_cast(_msg, ctx) do
    {:ok, ctx}
  end

  defp to_quoted(%{"keyword" => ""}) do
    quote do
      Kino.inspect("Enter a keyword to get started")
    end
  end

  defp to_quoted(%{"keyword" => keyword}) do
    quote do
      frame = Kino.Frame.new()

      Kino.Frame.render(frame, Kino.Text.new("Running..."))

      keywords =
        unquote(keyword)
        |> KinoAmazonKeywords.Keywords.fetch()
        |> Explorer.Series.from_list(dtype: :string)

      data_frame = Explorer.DataFrame.new(keywords: keywords)

      # Kino.Frame.render(frame, data_frame)
      Kino.Shorts.data_table(data_frame)
    end
  end

  defp to_quoted(_attrs) do
    quote do
      Kino.inspect("loaded...")
    end
  end
end
