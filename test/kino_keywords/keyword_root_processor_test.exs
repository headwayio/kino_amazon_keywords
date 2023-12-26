defmodule KinoKeywords.KeywordRootProcessorTest do
  use ExUnit.Case, async: true

  alias KinoKeywords.KeywordRootProcessor
  alias KinoKeywords.TwoRootRow

  test "extract one root keywords" do
    keywords =
      [
        %{"Search Term" => "candle", "TV (total volume)" => 5, "Relevancy (%)" => 0.95},
        %{"Search Term" => "holiday candles", "TV (total volume)" => 3, "Relevancy (%)" => 0.75},
        %{
          "Search Term" => "scented candles for holiday",
          "TV (total volume)" => 1,
          "Relevancy (%)" => 0.5
        },
        %{"Search Term" => "scented candles", "TV (total volume)" => 2, "Relevancy (%)" => 0.25}
      ]
      |> KeywordRootProcessor.process_one_root_keywords()
      |> Enum.sort(&(&1["OneRoot"] < &2["OneRoot"]))

    # Equation for volume: Sum of each root word (total volume * relevancy)
    # Equation for frequency: Count of each root word
    assert keywords == [
             %{"OneRoot" => "candle", "Volume" => 4.75, "Frequency" => 1},
             %{"OneRoot" => "candles", "Volume" => 3 * 0.75 + 0.5 + 0.5, "Frequency" => 3},
             %{"OneRoot" => "for", "Volume" => 0.5, "Frequency" => 1},
             %{"OneRoot" => "holiday", "Volume" => 3 * 0.75 + 0.5, "Frequency" => 2},
             %{"OneRoot" => "scented", "Volume" => 1, "Frequency" => 2}
           ]
  end

  test "extract two root keywords" do
    one_root_data =
      [
        %{"Search Term" => "candle", "TV (total volume)" => 5, "Relevancy (%)" => 0.95},
        %{"Search Term" => "holiday candles", "TV (total volume)" => 3, "Relevancy (%)" => 0.75},
        %{
          "Search Term" => "scented candles for the holidays",
          "TV (total volume)" => 2,
          "Relevancy (%)" => 0.25
        }
      ]

    one_root_rows =
      one_root_data
      |> KeywordRootProcessor.process_one_root_keywords()

    result = KeywordRootProcessor.process_two_root_keywords(one_root_data, one_root_rows)

    assert [
             %TwoRootRow{
               root: "holiday candles",
               volume: 2.25,
               keyword_count: 1,
               keywords: [%{keyword: "holiday candles", volume: 2.25}]
             },
             %TwoRootRow{
               root: "candles for",
               volume: 0.5,
               keyword_count: 1,
               keywords: [%{keyword: "scented candles for the holidays", volume: 0.5}]
             },
             %TwoRootRow{
               root: "for the",
               volume: 0.5,
               keyword_count: 1,
               keywords: [%{keyword: "scented candles for the holidays", volume: 0.5}]
             },
             %TwoRootRow{
               root: "scented candles",
               volume: 0.5,
               keyword_count: 1,
               keywords: [%{keyword: "scented candles for the holidays", volume: 0.5}]
             },
             %TwoRootRow{
               root: "the holidays",
               volume: 0.5,
               keyword_count: 1,
               keywords: [%{keyword: "scented candles for the holidays", volume: 0.5}]
             }
           ] == result
  end
end
