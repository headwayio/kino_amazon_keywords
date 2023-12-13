defmodule KinoAmazonKeywords.Keywords do
  @moduledoc """
  Fetch keywords from Amazon
  """

  @suggestion_type1 "KEYWORD"
  @suggestion_type2 "WIDGET"

  @doc """
  Fetch top keywords matching the given keyword.
  Optionally request variants which will append A-Z to the keyword
  and will generate related keywords for each variant.

  ## Examples

      iex> KinoAmazonKeywords.Keywords.fetch("candles")
      {["candles", "holiday candles", "candles scented"], []}

      iex> KinoAmazonKeywords.Keywords.fetch("candles", true)
      {["candles", "holiday candles", "candles scented"], ["candles advent", "candles aroma therapy", "candles accessory"]}

  """
  def fetch(prefix, generate_variants \\ false) do
    urls =
      if generate_variants do
        variants =
          ?a..?z
          |> Enum.map(fn item -> List.to_string([item]) end)
          |> Enum.map(fn item -> generate_url(prefix <> " " <> item) end)

        [generate_url(prefix)] ++ variants
      else
        [generate_url(prefix)]
      end

    [original_keywords | variant_keywords] =
      urls
      |> Stream.map(fn item ->
        {:ok, response} = Req.get(item)

        response.body["suggestions"]
        |> Enum.map(fn item -> item["value"] end)
        |> Enum.uniq()
      end)
      |> Enum.to_list()

    variant_keywords = List.flatten(variant_keywords)

    {original_keywords, variant_keywords}
  end

  def generate_url(prefix) do
    last_prefix = prefix

    "https://completion.amazon.com/api/2017/suggestions?limit=11&prefix=#{prefix}&suggestion-type=#{@suggestion_type1}&suggestion-type=#{@suggestion_type2}&page-type=Search&alias=aps&site-variant=desktop&version=3&event=onkeypress&wc=&lop=en_US&last-prefix=#{last_prefix}&avg-ks-time=567&fb=1&session-id=147-2944963-3693218&request-id=9TT8PTZBJASW7WDSG87R&mid=ATVPDKIKX0DER&plain-mid=1&client-info=amazon-search-ui"
    |> URI.encode()
  end

  def images(prefix) do
    url =
      "https://www.amazon.com/s?k=#{prefix}"
      |> URI.encode()

    {:ok, response} = Req.get(url)
    {:ok, html} = Floki.parse_document(response.body)

    products = Floki.find(html, ".s-search-results [data-component-type=\"s-search-result\"]")

    images =
      products
      |> Floki.find(".s-product-image-container")
      |> Enum.map(fn item ->
        image =
          item
          |> Floki.attribute("img", "src")
          |> Enum.at(0)

        url =
          item
          |> Floki.attribute("a:first-child", "href")
          |> Enum.at(0)

        {image, url}
      end)

    details =
      products
      |> Floki.find(".s-product-image-container + div")
      |> Enum.map(fn item ->
        text =
          item
          |> Floki.find("h2:first-child span")
          |> Floki.text()

        text
      end)

    details
    |> Enum.zip(images)
    |> Enum.map(fn {title, {image, url}} ->
      %{title: title, image: image, product_url: url}
    end)
  end
end
