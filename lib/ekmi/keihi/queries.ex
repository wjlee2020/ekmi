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
end
