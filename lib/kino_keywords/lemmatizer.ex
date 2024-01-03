defmodule KinoKeywords.Lemmatizer do
  use Export.Python

  @type root_word() :: %{root: string(), volume: float(), frequency: float()}

  @spec main(list(root_word())) :: list(root_word())
  def main(keyword_list) do
    {:ok, py} = start_python()

    val = Python.call(py, main(keyword_list), from_file: "word_net_lemmatizer")

    # close the Python process
    Python.stop(py)

    val
  end

  def upcase(text) do
    # path to our python files
    {:ok, py} = start_python()

    # call "upcase" method from "test" file with "hello" argument
    py
    |> Python.call("lemmatizer", "upcase", [text])

    # same as above but prettier
    val = py |> Python.call(upcase(text), from_file: "lemmatizer")

    # close the Python process
    Python.stop(py)

    val
  end

  defp start_python do
    Python.start(python: "python3", python_path: python_modules_dir())
  end

  defp python_modules_dir do
    # path to our python files
    :kino_keywords
    |> :code.priv_dir()
    |> Path.join("python")
    |> Path.expand()
  end
end
