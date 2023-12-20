defmodule KinoKeywords.KeywordsCell do
  @moduledoc false
  use Kino.JS, assets_path: "lib/assets"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Keywords"

  def new do
    Kino.JS.new(__MODULE__, %{fields: %{}})
  end

  @impl true
  def init(attrs, ctx) do
    fields = %{
      "keyword" => attrs["keyword"] || "",
      "variants" => attrs["variants"] || false
    }

    ctx = assign(ctx, fields: fields)
    {:ok, ctx, reevaluate_on_change: true}
  end

  @impl true
  def handle_connect(ctx) do
    {:ok, %{fields: ctx.assigns[:fields]}, ctx}
  end

  @impl true
  def scan_binding(pid, binding, _env) do
    send(pid, {:scan_binding_result, binding})
  end

  @impl true
  def handle_info({:scan_binding_result, binding}, ctx) do
    data_frames =
      for {key, val} <- binding, valid_data?(val) do
        %{
          variable: Atom.to_string(key),
          data: val,
          data_frame: is_struct(val, Explorer.DataFrame)
        }
      end

    data_frame_variables =
      data_frames
      |> Enum.map(&{&1.variable, &1.data_frame})
      |> Enum.into(%{})

    ctx =
      assign(ctx,
        binding: binding,
        data_frames: data_frames,
        data_frame_variables: data_frame_variables
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
      "fields" => ctx.assigns.fields
    })

    {:noreply, ctx}
  end

  @impl true
  def to_attrs(ctx) do
    ctx.assigns.fields
  end

  @impl true
  def to_source(attrs) do
    attrs
    |> to_quoted()
    |> Kino.SmartCell.quoted_to_string()
  end

  @impl true
  def handle_event("update_keyword", value, ctx) do
    payload = %{"keyword" => value}
    ctx = update(ctx, :fields, &Map.merge(&1, payload))
    broadcast_event(ctx, "update", payload)
    {:noreply, ctx}
  end

  @impl true
  def handle_event("update_variants", value, ctx) do
    payload = %{"variants" => value}
    ctx = update(ctx, :fields, &Map.merge(&1, payload))
    broadcast_event(ctx, "update", payload)
    {:noreply, ctx}
  end

  @impl true
  def handle_cast(_msg, ctx) do
    {:ok, ctx}
  end

  defp to_quoted(%{"keyword" => ""}) do
    quote do
      Kino.nothing()
    end
  end

  defp to_quoted(%{"data_frame" => nil}) do
    quote do
      Kino.nothing()
    end
  end

  defp to_quoted(%{"data_frame" => data_frame, "assign_to" => variable} = attrs) do
    variable = if variable && Kino.SmartCell.valid_variable_name?(variable), do: variable

    nodes =
      []
      |> maybe_build_df(attrs)
      |> lazy(attrs)
      # |> maybe_collect(attrs, idx)
      |> maybe_clean_up(attrs)

    root = build_root(data_frame)

    nodes
    |> Enum.reduce(root, &apply_node/2)
    |> build_var(variable)
  end

  defp to_quoted(%{"keyword" => keyword, "variants" => variants}) do
    quote do
      {keywords, variant_keywords} =
        unquote(keyword)
        |> KinoKeywords.Keywords.fetch(unquote(variants))

      keyword_series = Explorer.Series.from_list(keywords, dtype: :string)
      keyword_df = Explorer.DataFrame.new(Keywords: keyword_series)

      variant_keyword_series = Explorer.Series.from_list(variant_keywords, dtype: :string)
      variant_keyword_df = Explorer.DataFrame.new(Variants: variant_keyword_series)

      items =
        if unquote(variants) do
          [Keywords: keyword_df, Variants: variant_keyword_df]
        else
          [Keywords: keyword_df]
        end

      Kino.Shorts.tabs(items)
    end
  end

  defp to_quoted(attrs) do
    dbg(attrs)
    quote do
      Kino.inspect("loaded...")
    end
  end

  defp valid_data?(%Explorer.DataFrame{}), do: true

  defp valid_data?(data) do
    with true <- implements?(Table.Reader, data),
         {_, %{columns: [_ | _] = columns}, _} <- Table.Reader.init(data),
         true <- Enum.all?(columns, &implements?(String.Chars, &1)) do
      true
    else
      _ -> false
    end
  end

  defp implements?(protocol, value), do: protocol.impl_for(value) != nil

  defp updates_for_data_frame(data_frame, _ctx) do
    %{
      fields: %{
        "data_frame" => data_frame
      }
    }
  end

  defp build_var(acc, nil), do: acc

  defp build_var(acc, var) do
    quote do
      unquote({String.to_atom(var), [], nil}) = unquote(acc)
    end
  end

  defp convert_field(field, nil), do: {String.to_atom(field), nil}
  defp convert_field(field, ""), do: {String.to_atom(field), nil}
  defp convert_field(field, value), do: {String.to_atom(field), value}

  defp maybe_build_df(nodes, %{is_data_frame: true}), do: nodes
  defp maybe_build_df(nodes, attrs), do: [build_df("Explorer.DataFrame") | nodes]

  defp lazy(nodes, %{is_data_frame: false}), do: nodes
  defp lazy(nodes, attrs), do: [build_lazy("Explorer.DataFrame") | nodes]

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
    dbg(df)
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

  defp apply_node(%{args: nil}, acc), do: acc

  defp apply_node(%{field: _field, name: function, module: data_frame, args: args}, acc) do
    quote do
      unquote(acc) |> unquote(data_frame).unquote(function)(unquote_splicing(args))
    end
  end

  defp collect_index([_ | rest], size, idx), do: collect_index(rest, size, idx + 1)
  defp collect_index([], _size, _idx), do: nil
end
