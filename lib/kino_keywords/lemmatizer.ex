defmodule KinoKeywords.Lemmatizer do
  use Export.Python

  def upcase(text) do
    # path to our python files
    {:ok, py} = Python.start(python_path: Path.expand("lib/python"))

    # call "upcase" method from "test" file with "hello" argument
    py
    |> Python.call("lemmatizer", "upcase", [text])

    # same as above but prettier
    val = py |> Python.call(upcase(text), from_file: "lemmatizer")

    # close the Python process
    Python.stop(py)

    val
  end

  def main() do
    # path to our python files
    {:ok, py} = Python.start(python_path: Path.expand("lib/python"))

    val = py |> Python.call(main(), from_file: "word_net_lemmatizer")

    # close the Python process
    Python.stop(py)

    val
  end
end
