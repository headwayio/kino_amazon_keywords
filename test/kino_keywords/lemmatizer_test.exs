defmodule KinoKeywords.LemmatizerTest do
  use ExUnit.Case, async: true

  alias KinoKeywords.Lemmatizer

  test "upcases" do
    assert "HELLO" == Lemmatizer.upcase("hello")
  end

  test "main" do
    assert "HELLO" == Lemmatizer.main()
  end
end
