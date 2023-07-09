defmodule Ekmi.Keihi.Queries do
  @moduledoc false

  import Ecto.Query
  alias Ekmi.Keihi.Budget

  def where_user_and_budget_ids(%{user_id: user_id, budget_id: budget_id}) do
    from b in Budget,
      where: b.user_id == ^user_id and b.id == ^budget_id,
      preload: [:category]
  end

  def where_user(%{user_id: user_id}) do
    from b in Budget,
      where: b.user_id == ^user_id,
      preload: [:category]
  end

  def paginate(query, %{page: page, per_page: per_page}) do
    offset = max((page - 1) * per_page, 0)

    query
    |> limit(^per_page)
    |> offset(^offset)
  end

  def paginate(query, _options), do: query

  def records_for_month(query, %{year: year, month: month}) do
    from(r in query,
      where: fragment("date_trunc('month', ?) = date ?", r.inserted_at, ^"#{year}-#{month}-01")
    )
  end

  def records_for_month(query, _options), do: query

  def sort(query, %{sort_by: sort_by, sort_order: sort_order}) do
    order_by(query, {^sort_order, ^sort_by})
  end

  def sort(query, _options), do: query
end
