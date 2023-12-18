defmodule KinoKeywords.KeywordsTest do
  use ExUnit.Case, async: true

  alias KinoKeywords.Keywords

  test "skips variants" do
    {left, right} = Keywords.fetch("candle", true)
    assert [] == right
  end

  test "products" do
    image_urls = Keywords.images("candles")
  end
end
