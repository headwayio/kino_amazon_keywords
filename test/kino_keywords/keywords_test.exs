defmodule KinoKeywords.KeywordsTest do
  use ExUnit.Case, async: true

  alias KinoKeywords.Http.Client

  import Mock

  alias KinoKeywords.Keywords

  test "skips variants" do
    http_response = {:ok, %{body: %{"suggestions" => [%{"value" => "foo"}]}}}

    with_mock Client, get: fn _url -> http_response end do
      {left, _right} = Keywords.fetch("candle", false)
      assert ["foo"] == left
    end
  end

  test "generates variants" do
    with_mock Client, get: fn _url -> {:ok, %{body: %{"suggestions" => []}}} end do
      Keywords.fetch("candle", true)
      assert_called_exactly(Client.get(:_), 27)
    end
  end
end
