defmodule KinoAmazonKeywords.KeywordsTest do
  use ExUnit.Case, async: true

  alias KinoAmazonKeywords.Keywords

  test "skips variants" do
    {left, right} = Keywords.fetch("candle", true)
    assert [] == right
  end
end
