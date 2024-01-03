defmodule KinoKeywords.LemmatizerTest do
  use ExUnit.Case, async: true

  alias KinoKeywords.Lemmatizer

  test "foo" do
    dbg(Lemmatizer.foo())
  end

  test "upcase" do
    assert %{"foo" => "HELLO"} == Lemmatizer.upcase("hello")
  end

  test "main" do
    keywords =
      [
        %{
          "root" => "candles",
          "volume" => 2.75,
          "frequency" => 2
        },
        %{
          "root" => "candle",
          "volume" => 4.75,
          "frequency" => 1
        },
        %{
          "root" => "holiday",
          "volume" => 2.25,
          "frequency" => 1
        },
        %{
          "root" => "scented",
          "volume" => 0.5,
          "frequency" => 1
        },
        %{
          "root" => "the",
          "volume" => 0.5,
          "frequency" => 1
        },
        %{
          "root" => "holidays",
          "volume" => 0.5,
          "frequency" => 1
        },
        %{
          "root" => "holiday candles",
          "volume" => 2.25,
          "frequency" => 1
        }
      ]
      |> Jason.encode!()
      |> Lemmatizer.main()
      |> Jason.decode!()

    assert [
             %{
               "root" => "candle",
               "volume" => 7.5,
               "frequency" => 3
             },
             %{
               "root" => "holiday",
               "volume" => 2.75,
               "frequency" => 2
             },
             %{
               "root" => "scented",
               "volume" => 0.5,
               "frequency" => 1
             },
             %{
               "root" => "the",
               "volume" => 0.5,
               "frequency" => 1
             },
             %{
               "root" => "holiday candle",
               "volume" => 2.25,
               "frequency" => 1
             }
           ] == keywords
  end
end
