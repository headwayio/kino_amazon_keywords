defmodule KinoKeywords.KeywordRootAnalysisCell do
  @moduledoc false
  use Kino.JS, assets_path: "lib/assets/keyword-root-analysis"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Keyword Root Analysis"

  alias Explorer.DataFrame
  alias KinoKeywords.KeywordRootProcessor

  def new do
    Kino.JS.new(__MODULE__, %{fields: %{}})
  end

  @impl true
  def init(attrs, ctx) do
    fields = %{
      "normalize" => attrs["normalize"] || false,
      "negative_keywords" => attrs["negative_keywords"] || [],
      "data_frame" => attrs["data_frame"],
      "assign_to" => attrs["assign_to"],
      "collect" => if(Map.has_key?(attrs, "collect"), do: attrs["collect"], else: true)
    }

    ctx =
      assign(ctx,
        fields: fields,
        data_frame_alias: Explorer.DataFrame,
        data_frame_variables: %{},
        data_frames: [],
        binding: [],
        missing_require: nil
      )

    {:ok, ctx, reevaluate_on_change: true}
  end

  @impl true
  def scan_binding(pid, binding, env) do
    data_frame_alias = data_frame_alias(env)
    missing_require = missing_require(env)

    send(pid, {:scan_binding_result, binding, data_frame_alias, missing_require})
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{
      fields: ctx.assigns.fields,
      data_frame_variables: ctx.assigns.data_frame_variables,
      missing_require: ctx.assigns.missing_require,
      data_frame_alias: ctx.assigns.data_frame_alias
    }

    {:ok, payload, ctx}
  end

  @impl true
  def handle_info({:scan_binding_result, binding, data_frame_alias, missing_require}, ctx) do
    data_frames =
      for {key, val} <- binding,
          valid_data(val),
          do: %{
            variable: Atom.to_string(key),
            data: val,
            data_frame: is_struct(val, DataFrame)
          }

    data_frame_variables = Enum.map(data_frames, &{&1.variable, &1.data_frame}) |> Enum.into(%{})

    ctx =
      assign(ctx,
        binding: binding,
        data_frames: data_frames,
        data_frame_variables: data_frame_variables,
        data_frame_alias: data_frame_alias,
        missing_require: missing_require
      )

    updated_fields =
      case {ctx.assigns.fields["data_frame"], Map.keys(data_frame_variables)} do
        {nil, [data_frame | _]} ->
          updates_for_data_frame(data_frame, ctx)

        _ ->
          %{fields: ctx.assigns.fields}
      end

    ctx = assign(ctx, updated_fields)

    broadcast_event(ctx, "set_available_data", %{
      "data_frame_variables" => data_frame_variables,
      "data_frame_alias" => data_frame_alias,
      "fields" => updated_fields
    })

    {:noreply, ctx}
  end

  @impl true
  def to_attrs(ctx) do
    ctx.assigns.fields
    |> Map.put("data_frame_alias", ctx.assigns.data_frame_alias)
    |> Map.put("missing_require", ctx.assigns.missing_require)
    |> Map.put("is_data_frame", is_data_frame?(ctx))
  end

  @impl true
  def to_source(attrs) do
    attrs
    |> to_quoted()
    |> Kino.SmartCell.quoted_to_string()
  end

  @impl true
  def handle_event("update_data_frame", %{"field" => "data_frame", "value" => value}, ctx) do
    updated_fields = updates_for_data_frame(value, ctx)
    ctx = assign(ctx, updated_fields)
    broadcast_event(ctx, "update_data_frame", %{"fields" => updated_fields})
    {:noreply, ctx}
  end

  @impl true
  def handle_event("update_normalize", value, ctx) do
    payload = %{"normalize" => value}
    ctx = update(ctx, :fields, &Map.merge(&1, payload))
    broadcast_event(ctx, "update", payload)
    {:noreply, ctx}
  end

  @impl true
  def handle_event("update_negative_keywords", value, ctx) do
    payload = %{"negative_keywords" => value}
    ctx = update(ctx, :fields, &Map.merge(&1, payload))
    broadcast_event(ctx, "update", payload)
    {:noreply, ctx}
  end

  @impl true
  def handle_cast(_msg, ctx) do
    {:ok, ctx}
  end

  defp to_quoted(%{"data_frame" => nil}),
    do: Kino.Shorts.text("Select a data frame to get started")

  defp to_quoted(%{"data_frame" => ""}),
    do: Kino.Shorts.text("Select a data frame to get started")

  defp to_quoted(%{"data_frame" => df, "assign_to" => variable} = attrs) do
    attrs = Map.new(attrs, fn {k, v} -> convert_field(k, v) end)
    missing_require = attrs.missing_require
    variable = if variable && Kino.SmartCell.valid_variable_name?(variable), do: variable

    nodes = []

    idx = collect_index(nodes, length(nodes), 0)

    nodes =
      nodes
      |> maybe_build_df(attrs)
      |> lazy(attrs)
      |> maybe_collect(attrs, idx)
      |> maybe_clean_up(attrs)

    root = build_root(df)

    terms =
      nodes
      |> Enum.reduce(root, &apply_node/2)
      |> build_var(variable)
      |> build_missing_require(missing_require)

    quote do
      one_root_keywords =
        unquote(terms)
        |> Explorer.DataFrame.select(["Search Term", "TV (total volume)", "Relevancy (%)"])
        |> Explorer.DataFrame.collect()
        |> Explorer.DataFrame.to_rows()
        |> KinoKeywords.KeywordRootProcessor.process_one_root_keywords()

      two_root_keywords =
        unquote(terms)
        |> Explorer.DataFrame.select(["Search Term", "TV (total volume)", "Relevancy (%)"])
        |> Explorer.DataFrame.collect()
        |> Explorer.DataFrame.to_rows()
        |> KinoKeywords.KeywordRootProcessor.process_two_root_keywords(one_root_keywords)
        |> Enum.map(fn item ->
          %{root: item.root, volume: item.volume, keyword_count: item.keyword_count}
        end)
        # |> Enum.map(fn item ->
        #   keywords = Enum.map(item[:keywords], fn i -> "[#{i}]" end)
        #   Map.merge(item, %{keywords: keywords}) |> dbg()
        # end)
        |> Explorer.DataFrame.new()
    end
  end

  # https://app.windmill.dev/api/w/superdisco/jobs/run_wait_result/f/f/KeywordClustering/SearchQueryClustering

  defp data_frame_alias(%Macro.Env{aliases: aliases}) do
    case List.keyfind(aliases, Explorer.DataFrame, 1) do
      {data_frame_alias, _} -> data_frame_alias
      nil -> Explorer.DataFrame
    end
  end

  defp missing_require(%Macro.Env{requires: requires}) do
    if Explorer.DataFrame not in requires, do: Explorer.DataFrame
  end

  defp updates_for_data_frame(data_frame, _ctx) do
    %{
      fields: %{
        "data_frame" => data_frame,
        "assign_to" => nil,
        "lazy" => true,
        "collect" => false
      }
    }
  end

  defp valid_data(%DataFrame{}), do: true

  defp valid_data(data) do
    with true <- implements?(Table.Reader, data),
         {_, %{columns: [_ | _] = columns}, _} <- Table.Reader.init(data),
         true <- Enum.all?(columns, &implements?(String.Chars, &1)) do
      true
    else
      _ -> false
    end
  end

  defp implements?(protocol, value), do: protocol.impl_for(value) != nil

  defp is_data_frame?(ctx) do
    df = ctx.assigns.fields["data_frame"]
    Map.get(ctx.assigns.data_frame_variables, df)
  end

  defp convert_field(field, nil), do: {String.to_atom(field), nil}
  defp convert_field(field, ""), do: {String.to_atom(field), nil}
  defp convert_field(field, value), do: {String.to_atom(field), value}

  defp collect_index([%{name: :group_by}, %{name: :summarise} | rest], size, idx) do
    collect_index(rest, size, idx + 2)
  end

  defp collect_index([%{name: :group_by} | _], size, idx), do: if(idx < size - 1, do: idx + 1)
  defp collect_index([%{name: :pivot_wider}], _size, idx), do: idx
  defp collect_index([_ | rest], size, idx), do: collect_index(rest, size, idx + 1)
  defp collect_index([], _size, _idx), do: nil

  defp maybe_build_df(nodes, %{is_data_frame: true}), do: nodes
  defp maybe_build_df(nodes, attrs), do: [build_df(attrs.data_frame_alias) | nodes]

  defp lazy(nodes, %{is_data_frame: false}), do: nodes
  defp lazy(nodes, attrs), do: [build_lazy(attrs.data_frame_alias) | nodes]

  defp maybe_collect(nodes, %{collect: false}, nil), do: nodes

  defp maybe_collect(nodes, %{collect: true} = attrs, nil) do
    nodes ++ [build_collect(attrs.data_frame_alias)]
  end

  defp maybe_collect(nodes, %{data_frame_alias: data_frame_alias}, idx) do
    {lazy, collected} = Enum.split(nodes, idx + 1)
    lazy ++ [build_collect(data_frame_alias)] ++ collected
  end

  defp maybe_collect(nodes, _, _), do: nodes

  defp maybe_clean_up([%{args: [[lazy: true]]} = new, %{field: :collect} | nodes], _) do
    [%{new | args: []} | nodes]
  end

  defp maybe_clean_up([%{field: :lazy}, %{field: :collect} | nodes], _), do: nodes

  defp maybe_clean_up(nodes, _) do
    if Enum.all?(nodes, &(!&1.args || &1.args == [])), do: [], else: nodes
  end

  defp build_root(df) do
    quote do
      unquote(Macro.var(String.to_atom(df), nil))
    end
  end

  defp build_df(module) do
    %{args: [[lazy: true]], field: :new, module: module, name: :new}
  end

  defp build_lazy(module) do
    %{args: [], field: :lazy, module: module, name: :lazy}
  end

  defp build_collect(module) do
    %{args: [], field: :collect, module: module, name: :collect}
  end

  defp build_var(acc, nil), do: acc

  defp build_var(acc, var) do
    quote do
      unquote({String.to_atom(var), [], nil}) = unquote(acc)
    end
  end

  defp build_missing_require(acc, nil), do: acc

  defp build_missing_require(acc, missing_require) do
    quote do
      require unquote(missing_require)
      unquote(acc)
    end
  end

  defp apply_node(%{args: nil}, acc), do: acc

  defp apply_node(%{field: _field, name: function, module: data_frame, args: args}, acc) do
    quote do
      unquote(acc) |> unquote(data_frame).unquote(function)(unquote_splicing(args))
    end
  end
end
