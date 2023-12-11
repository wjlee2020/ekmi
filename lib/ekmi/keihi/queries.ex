defmodule Ekmi.Keihi.Queries do
  @moduledoc false

  import Ecto.Query
  alias Ekmi.Accounts.User
  alias Ekmi.Accounts.Account
  alias Ekmi.Keihi.Budget
  alias Ekmi.Repo

  def where_user_and_budget_ids(%{user_id: user_id, budget_id: budget_id}) do
    from b in Budget,
      where: b.user_id == ^user_id and b.id == ^budget_id,
      preload: [:category]
  end

  def where_account_and_budget_ids(%{account_id: account_id, budget_id: budget_id}) do
    from b in Budget,
      where: b.account_id == ^account_id and b.id == ^budget_id,
      preload: [:category]
  end

  def where_account(%Account{} = account) do
    case account
         |> Repo.preload(:partner_relation)
         |> Map.get(:partner_relation) do
      nil ->
        from b in Budget,
          where: b.account_id == ^account.id,
          preload: [:category]

      partner_relation ->
        from b in Budget,
          where:
            b.account_id == ^account.id or b.account_id == ^partner_relation.partner_account_id,
          preload: [:category]
    end
  end

  def where_user(%User{} = user) do
    case user
         |> Repo.preload(:partner_relation)
         |> Map.get(:partner_relation) do
      nil ->
        from b in Budget,
          where: b.user_id == ^user.id,
          preload: [:category]

      partner_relation ->
        from b in Budget,
          where: b.user_id == ^user.id or b.user_id == ^partner_relation.partner_id,
          preload: [:category]
    end
  end

  def paginate(query, %{page: page, per_page: per_page}) do
    offset = max((page - 1) * per_page, 0)

    query
    |> limit(^per_page)
    |> offset(^offset)
  end

  def paginate(query, _options), do: query

  def records_for_month(query, %{year: year}) when is_nil(year), do: query

  def records_for_month(query, %{year: year, month: month}) do
    from(b in query,
      where:
        fragment(
          "extract(year from ?) = ? and extract(month from ?) = ?",
          b.created_at,
          ^year,
          b.created_at,
          ^month
        )
    )
  end

  def records_for_month(query, _options), do: query

  def sort(query, %{sort_by: sort_by, sort_order: sort_order}) do
    order_by(query, {^sort_order, ^sort_by})
  end

  def sort(query, _options), do: query
end
