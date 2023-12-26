defmodule KinoKeywords.KeywordRootProcessor do
  alias KinoKeywords.{KeywordRow, TwoRootRow, KeywordRow2}

  @doc """
    Extracts one root keywords from a list of keyword rows.

    Keyword rows are maps with the following keys:
    - "Search Term"
    - "TV (total volume)"
    - "Relevancy (%)"


  """
  def process_one_root_keywords(keyword_rows, negative_keywords \\ []) do
    %{roots: roots, keyword_counts: keyword_counts} =
      Enum.reduce(
        keyword_rows,
        %{roots: %{}, keyword_counts: %{}},
        fn %{
             "Relevancy (%)" => relevancy,
             "Search Term" => search_term,
             "TV (total volume)" => total_volume
           },
           acc ->
          %KeywordRow{
            Keyword: search_term,
            SearchVolume: total_volume,
            Relevancy: relevancy
          }
          |> process_row(acc)
        end
      )

    output_data =
      roots
      |> Map.to_list()
      |> Enum.map(&convert_to_output_data(&1, keyword_counts))
      |> sort_output_data()

    output_data = filter_negative_keywords(output_data, negative_keywords)

    output_data
  end

  def process_two_root_keywords(keyword_rows, one_root_rows, negative_keywords \\ []) do
    roots_map =
      Enum.reduce(one_root_rows, %{}, fn row, acc ->
        root = String.trim(row["OneRoot"])

        if root != "" do
          Map.put(acc, root, row["Volume"])
        else
          acc
        end
      end)

    two_roots_map =
      Enum.reduce(roots_map, %{}, fn {root, _}, acc ->
        Enum.reduce(roots_map, acc, fn {inner_root, _}, acc ->
          if root != inner_root && String.trim(inner_root) != "" do
            two_root = "#{root} #{inner_root}"

            Map.put(acc, two_root, %TwoRootRow{
              root: two_root,
              volume: 0,
              keyword_count: 0,
              keywords: []
            })
          else
            acc
          end
        end)
      end)

    two_roots_map =
      Enum.reduce(keyword_rows, two_roots_map, fn %{
                                                    "Search Term" => keyword,
                                                    "TV (total volume)" => raw_volume,
                                                    "Relevancy (%)" => relevancy
                                                  },
                                                  acc ->
        volume = raw_volume * relevancy

        words = String.split(keyword, " ")

        Enum.reduce(0..(length(words) - 2), acc, fn i, two_root_acc ->
          possible_two_root =
            words
            |> Enum.slice(i, 2)
            |> Enum.join(" ")

          case Map.get(two_root_acc, possible_two_root) do
            %TwoRootRow{} = two_root ->
              updated_two_root = update_two_root(two_root, volume, keyword)

              %{two_root_acc | possible_two_root => updated_two_root}

            _ ->
              two_root_acc
          end
        end)
      end)

    two_roots_map
    |> Map.values()
    |> Enum.sort_by(& &1.volume, &>=/2)
    |> Enum.filter(&(&1.keyword_count != 0))
    |> Enum.filter(fn x -> !Enum.any?(negative_keywords, &String.contains?(x.root, &1)) end)
  end

  defp process_row(
         %KeywordRow{Keyword: keyword, SearchVolume: raw_volume, Relevancy: relevancy},
         acc
       ) do
    keyword_roots = String.split(keyword, " ")

    Enum.reduce(keyword_roots, acc, fn root, acc ->
      process_root(root, raw_volume, relevancy, acc)
    end)
  end

  defp process_root(root, raw_volume, relevancy, %{roots: roots, keyword_counts: keyword_counts}) do
    root = String.trim(root)

    if !String.match?(root, ~r/\d/) and root != "" do
      volume = raw_volume * relevancy

      updated_roots =
        case Map.get(roots, root) do
          nil -> Map.put(roots, root, volume)
          existing_volume -> Map.put(roots, root, existing_volume + volume)
        end

      updated_counts =
        case Map.get(keyword_counts, root) do
          nil -> Map.put(keyword_counts, root, 1)
          existing_count -> Map.put(keyword_counts, root, existing_count + 1)
        end

      %{roots: updated_roots, keyword_counts: updated_counts}
    else
      %{roots: roots, keyword_counts: keyword_counts}
    end
  end

  defp convert_to_output_data({root, volume}, keyword_counts) do
    %{"OneRoot" => root, "Volume" => volume, "Frequency" => Map.get(keyword_counts, root)}
  end

  defp sort_output_data(output_data) do
    Enum.sort_by(output_data, &Map.get(&1, "Volume"), &>=/2)
  end

  defp filter_negative_keywords(output_data, negative_keywords) do
    Enum.filter(output_data, fn x ->
      !Enum.any?(negative_keywords, &String.contains?(x["OneRoot"], &1))
    end)
  end

  def check_contains_two_root(keyword, two_root) do
    words = String.split(keyword, " ")

    Enum.reduce(0..(length(words) - 2), false, fn i, acc ->
      acc or Enum.slice(words, i, 2) |> Enum.join(" ") == two_root
    end)
  end

  defp update_two_root(
         %TwoRootRow{
           volume: current_volume,
           keyword_count: current_count,
           keywords: current_keywords
         } = two_root,
         volume,
         keyword
       ) do
    %TwoRootRow{
      two_root
      | volume: current_volume + volume,
        keyword_count: current_count + 1,
        keywords: [%{keyword: keyword, volume: volume} | current_keywords]
    }
  end
end
