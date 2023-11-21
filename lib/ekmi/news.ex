defmodule Ekmi.News do
  @moduledoc """
  News Module for handling all things news related.
  """

  use Tesla

  adapter(Tesla.Adapter.Hackney)
  plug Tesla.Middleware.JSON

  @api_key System.get_env("NEWS_API_KEY")
  @base_url "https://newsapi.org/v2"

  def get_news(query) do
    get(@base_url,
      query: [
        q: query,
        from: NaiveDateTime.local_now() |> NaiveDateTime.to_date() |> Date.to_iso8601(),
        sortBy: "popularity",
        apiKey: @api_key
      ]
    )
  end

  def get_top_headlines(country) do
    get("#{@base_url}/top-headlines",
      query: %{
        country: country,
        apiKey: @api_key
      }
    )
  end
end
