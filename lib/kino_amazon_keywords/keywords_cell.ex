defmodule KinoAmazonKeywords.KeywordsCell do
  @moduledoc """
  Documentation for `KinoAmazonKeywords`.
  """
  use Kino.JS
  use Kino.JS.Live
  use Kino.SmartCell, name: "Amazon Keywords"

  @impl true
  def init(_attrs, ctx) do
    {:ok, ctx}
  end

  # Other Kino.JS.Live callbacks

  @impl true
  def handle_connect(ctx) do
    {:ok, %{}, ctx}
  end

  @impl true
  def to_attrs(_ctx) do
    %{}
  end

  @impl true
  def to_source(_attrs) do
    "Hello world"
  end

  asset "main.js" do
    """
    export function init(ctx, payload) {
      ctx.importCSS("main.css");

      ctx.root.innerHTML = `
        <textarea id="source"></textarea>
      `;
    }
    """
  end

  @doc """
  Hello world.

  ## Examples

      iex> KinoAmazonKeywords.hello()
      :world

  """
  def hello do
    {:ok, response} = Req.get("https://www.amazon.com")

    response.body

    prefix = "candles"
    last_prefix = prefix
    suggestion_type1 = "KEYWORD"
    suggestion_type2 = "WIDGET"

    url =
      "https://completion.amazon.com/api/2017/suggestions?limit=11&prefix=#{prefix}&suggestion-type=#{suggestion_type1}&suggestion-type=#{suggestion_type2}&page-type=Search&alias=aps&site-variant=desktop&version=3&event=onkeypress&wc=&lop=en_US&last-prefix=#{last_prefix}&avg-ks-time=567&fb=1&session-id=147-2944963-3693218&request-id=9TT8PTZBJASW7WDSG87R&mid=ATVPDKIKX0DER&plain-mid=1&client-info=amazon-search-ui"

    {:ok, response} = Req.get(url)

    response.body["suggestions"]
    |> Enum.map(fn item -> item["value"] end)
    |> Enum.uniq()
    |> Explorer.Series.from_list()
  end
end
