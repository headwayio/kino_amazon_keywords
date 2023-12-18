defmodule KinoKeywords.KeywordsCell do
  @moduledoc false
  use Kino.JS, assets_path: "lib/assets"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Keywords"

  def new do
    Kino.JS.new(__MODULE__, %{fields: %{}})
  end

  @impl true
  def init(attrs, ctx) do
    fields = %{
      "keyword" => attrs["keyword"] || "",
      "variants" => attrs["variants"] || false
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
    payload = %{"keyword" => value}
    ctx = update(ctx, :fields, &Map.merge(&1, payload))
    broadcast_event(ctx, "update", payload)
    {:noreply, ctx}
  end

  @impl true
  def handle_event("update_variants", value, ctx) do
    payload = %{"variants" => value}
    ctx = update(ctx, :fields, &Map.merge(&1, payload))
    broadcast_event(ctx, "update", payload)
    {:noreply, ctx}
  end

  @impl true
  def handle_cast(_msg, ctx) do
    {:ok, ctx}
  end

  defp to_quoted(%{"keyword" => ""}) do
    quote do
      Kino.nothing()
    end
  end

  defp to_quoted(%{"keyword" => keyword, "variants" => variants}) do
    quote do
      {keywords, variant_keywords} =
        unquote(keyword)
        |> KinoKeywords.Keywords.fetch(unquote(variants))

      keyword_series = Explorer.Series.from_list(keywords, dtype: :string)
      keyword_df = Explorer.DataFrame.new(Keywords: keyword_series)

      variant_keyword_series = Explorer.Series.from_list(variant_keywords, dtype: :string)
      variant_keyword_df = Explorer.DataFrame.new(Variants: variant_keyword_series)

      items =
        if unquote(variants) do
          [Keywords: keyword_df, Variants: variant_keyword_df]
        else
          [Keywords: keyword_df]
        end

      Kino.Shorts.tabs(items)
    end
  end

  defp to_quoted(_attrs) do
    quote do
      Kino.inspect("loaded...")
    end
  end
end
