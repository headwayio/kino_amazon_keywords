defmodule KinoKeywords.KeywordsCellTest do
  use ExUnit.Case, async: true

  import Kino.Test

  alias KinoKeywords.KeywordsCell

  setup :configure_livebook_bridge

  @root %{
    "data_frame" => "keywords",
    "data_frame_alias" => Explorer.DataFrame,
    "missing_require" => nil,
    "is_data_frame" => true
  }

  defp candle_df do
    Explorer.DataFrame.new(%{keyword: ["candle"]})
  end

  defp build_attrs(root_attrs \\ %{}) do
    Map.merge(@root, root_attrs)
  end

  test "finds valid data in binding and sends the data options to the client" do
    {kino, _source} = start_smart_cell!(KeywordsCell, %{})

    keywords_df = candle_df()
    simple_data = [%{foo: "bar"}]

    env = Code.env_for_eval([])
    KeywordsCell.scan_binding(kino.pid, binding(), env)

    data_frame_variables = %{
      "keywords_df" => true,
      "simple_data" => false
    }

    assert_broadcast_event(kino, "set_available_data", %{
      "data_frame_variables" => ^data_frame_variables,
      "fields" => %{
        "data_frame" => "keywords_df"
      }
    })
  end

  describe "code generation" do
    test "default source" do
      attrs = build_attrs(%{})
      assert KeywordsCell.to_source(attrs) == "Kino.inspect(\"loaded...\")"
    end

    test "source with blank keyword" do
      attrs = build_attrs(%{"keyword" => ""})
      assert KeywordsCell.to_source(attrs) == "Kino.nothing()"
    end

    test "source with nil data frame" do
      attrs = build_attrs(%{"data_frame" => nil})
      assert KeywordsCell.to_source(attrs) == "Kino.nothing()"
    end

    test "source with data frame" do
      data_frame = candle_df()

      attrs = build_attrs(%{"data_frame" => data_frame, "assign_to" => "my_data_frame"})

      assert KeywordsCell.to_source(attrs) == "Kino.nothing()"
    end
  end
end
