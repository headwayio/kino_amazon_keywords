defmodule KinoAmazonKeywords.KeywordsByASINCell do
  @moduledoc false
  use Kino.JS, assets_path: "lib/assets/keywords-by-asin"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Amazon Keywords by ASIN"

  def new do
    Kino.JS.new(__MODULE__, %{fields: %{}})
  end

  @impl true
  def init(attrs, ctx) do
    fields = %{
      "asin" => attrs["asin"] || "B07G1VKCND",
      "competitors" => attrs["competitors"] || "B074PVTPBW, B08628VNNK, B075QNC39Q, B01N8XCGIO"
    }

    ctx = assign(ctx, fields: fields)
    {:ok, ctx, reevaluate_on_change: true}
  end

  @impl true
  def handle_connect(ctx) do
    {:ok, %{fields: ctx.assigns[:fields]}, ctx}
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
  def handle_event("update_asin", value, ctx) do
    payload = %{"asin" => value}
    ctx = update(ctx, :fields, &Map.merge(&1, payload))
    broadcast_event(ctx, "update", payload)
    {:noreply, ctx}
  end

  @impl true
  def handle_event("update_competitors", value, ctx) do
    payload = %{"competitors" => value}
    ctx = update(ctx, :fields, &Map.merge(&1, payload))
    broadcast_event(ctx, "update", payload)
    {:noreply, ctx}
  end

  @impl true
  def handle_cast(_msg, ctx) do
    {:ok, ctx}
  end

  defp to_quoted(%{"asin" => _asin, "competitors" => competitors}) do
    competitors = String.split(competitors, ~r/\W+/)

    if Enum.all?(competitors, fn item -> Regex.match?(~r/[a-zA-Z0-9]{10}/, item) end) do
      quote do
        auth_url = System.fetch_env!("LB_SMART_SCOUT_AUTH_URL")
        username = System.fetch_env!("LB_SMART_SCOUT_USERNAME")
        password = System.fetch_env!("LB_SMART_SCOUT_PASSWORD")

        {:ok, %{body: %{"token" => token}}} =
          Req.post(auth_url, json: %{username: username, password: password})

        headers = [
          {"Accept", "text/plain"},
          {"Accept-Encoding", "gzip, deflate"},
          {"Accept-Language", "en-US,en;q=0.9,ko;q=0.8"},
          {"Authorization", "Bearer #{token}"},
          {"Connection", "keep-alive"},
          {"Content-Type", "application/json-patch+json"},
          {"DNT", "1"},
          {"Host", "smartscoutapi-east.azurewebsites.net"},
          {"Origin", "https://app.smartscout.com"},
          {"Referer", "https://app.smartscout.com/"},
          {"Sec-Fetch-Dest", "empty"},
          {"Sec-Fetch-Mode", "cors"},
          {"Sec-Fetch-Site", "cross-site"},
          {"User-Agent",
           "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36"},
          {"X-SmartScout-Marketplace", "US"},
          {"traceparent", "00-4d9cc8f3d03145f18011b678d51daf76-57abe419d18646ee-01"}
        ]

        results =
          unquote(competitors)
          |> Task.async_stream(
            fn asin ->
              request_body = Jason.encode!(%{asin: asin})

              {:ok, %Req.Response{body: body}} =
                [
                  url: System.fetch_env!("LB_SMART_SCOUT_GET_ASIN_ID_URL"),
                  retry: :safe_transient,
                  receive_timeout: 40_000
                ]
                |> Req.new()
                |> Req.Request.put_headers(headers)
                |> Req.post(body: request_body)

              product_id = body["id"]

              request_body =
                Jason.encode!(%{
                  asin: asin,
                  productId: product_id,
                  estimateSearchesFactor: 100,
                  parentAsin: nil,
                  rankFactor: 100
                })

              case [
                     url: System.fetch_env!("LB_SMART_SCOUT_GET_ORGANIC_RANKS_URL"),
                     retry: :safe_transient,
                     receive_timeout: 40_000
                   ]
                   |> Req.new()
                   |> Req.Request.put_headers(headers)
                   |> Req.post(body: request_body) do
                {:ok, %Req.Response{body: body}} ->
                  body
                  |> Enum.map(fn item ->
                    search_term_product_ranks_dailies_count =
                      Enum.count(item["searchTermProductRanksDailies"])

                    recent_rank =
                      item["searchTermProductRanksDailies"]
                      |> Enum.reduce(0, fn v, acc ->
                        case v["avgRank"] do
                          num when is_float(num) -> acc + v["avgRank"]
                          _ -> acc
                        end
                      end)
                      |> Kernel./(search_term_product_ranks_dailies_count)

                    %{
                      search_term: item["searchTerm"]["searchTermValue"],
                      volume: item["searchTerm"]["estimateSearches"],
                      recent_rank: recent_rank,
                      asin: asin
                    }
                  end)

                error ->
                  error
              end
            end,
            timeout: 100_000
          )
          |> Enum.to_list()
          |> Enum.flat_map(fn {:ok, item} -> item end)

        total_asins = Enum.count(results)
        uniq_asins = Enum.uniq_by(results, fn item -> item[:asin] end)

        results
        |> Enum.reduce(%{}, fn item, acc ->
          term = item[:search_term]
          volume = item[:volume]
          recent_rank = item[:recent_rank]
          asin = item[:asin]

          case Map.get(acc, term) do
            nil ->
              asin_ranks = %{asin => recent_rank}
              Map.put(acc, term, %{asin_ranks: asin_ranks, tv: volume, count: 1})

            _row ->
              Map.update(acc, term, %{}, fn current ->
                {_, asin_ranks} =
                  Map.get_and_update(current[:asin_ranks], asin, fn rank ->
                    {rank, recent_rank}
                  end)

                %{
                  asin_ranks: asin_ranks,
                  tv: (current[:volume] || 0) + volume,
                  count: current[:count] + 1
                }
              end)
          end
        end)
        |> Enum.into([], fn {key, value} ->
          relevancy = Float.round(value[:count] / total_asins, 5)

          %{
            "Search Term" => key,
            "TV (total volume)" => value[:tv],
            "Relevancy %" => relevancy,
            "ASIN Ranks" => "TODO",
            "Data Source" => "Smart Scout"
          }
        end)
        |> Explorer.DataFrame.new()
        |> Explorer.DataFrame.relocate("Search Term", before: 0)
        |> Explorer.DataFrame.relocate("TV (total volume)", after: 0)
      end
    else
      quote do
        Kino.Shorts.text("Please enter a valid ASIN number")
      end
    end
  end
end
