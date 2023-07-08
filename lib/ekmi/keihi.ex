defmodule Ekmi.Keihi do
  @moduledoc false

  alias Ekmi.Keihi.{Budget, Queries}
  alias Ekmi.Repo

  def create_budget(attrs \\ %{}) do
    %Budget{}
    |> change_budget(attrs)
    |> Repo.insert()
  end

  def list_budgets(%{user_id: user_id}) do
    Repo.all(Queries.where_user%{user_id: user_id})
  end

  def find_budget(user_id, budget_id) do
    Repo.one(Queries.where_user_and_budget_ids%{user_id: user_id, budget_id: budget_id})
  end

  def change_budget(%Budget{} = budget, attr \\ %{}) do
    Budget.changeset(budget, attr)
  end
end
