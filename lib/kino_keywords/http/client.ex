defmodule KinoKeywords.Http.Client do
  @moduledoc """
  Req wrapper
  """

  @doc """
  Fetch the given URL and return the response body.

  ## Examples

      iex> KinoKeywords.Http.Client.get("https://www.google.com")
      {:ok, "<!doctype html>..."}
  """
  def get(url) do
    Req.get(url)
  end
end
