defmodule KinoKeywords.Lemmatizer do
  use Export.Python

  @type root_word() :: %{root: String.t(), volume: float(), frequency: float()}

  @spec main(list(root_word())) :: list(root_word())
  def main(keyword_list) do
    {:ok, py} = start_python()

    payload = Jason.encode!(keyword_list)

    val = Python.call(py, main(payload), from_file: "word_net_lemmatizer")

    # close the Python process
    Python.stop(py)

    val |> Jason.decode!()
  end

  def foo() do
    {:ok, py} = start_python()
    val = py |> Python.call(foo(), from_file: "lemmatizer")
    Python.stop(py)
    val |> Jason.decode!()
  end

  @spec upcase(String.t()) :: %{foo: String.t()}
  def upcase(text) do
    # path to our python files
    {:ok, py} = start_python()

    args = Jason.encode!(%{foo: text})

    # call "upcase" method from "test" file with "hello" argument
    py
    |> Python.call("lemmatizer", "upcase", [args])

    # same as above but prettier
    val = py |> Python.call(upcase(args), from_file: "lemmatizer")

    # close the Python process
    Python.stop(py)

    val |> Jason.decode!()
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
