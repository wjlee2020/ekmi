defmodule Ekmi.Keihi do
  @moduledoc false

  @topic inspect(__MODULE__)
  @pubsub Ekmi.PubSub

  alias Ekmi.Keihi.{Budget, Queries}
  alias Ekmi.Repo

  def subscribe do
    Phoenix.PubSub.subscribe(@pubsub, @topic)
  end

  def broadcast({:ok, budget}, tag) do
    Phoenix.PubSub.broadcast(
      @pubsub,
      @topic,
      {tag, budget}
    )

    {:ok, budget}
  end

  def broadcast({:error, _reason} = error, _tag), do: error

  def create_budget(attrs \\ %{}) do
    %Budget{}
    |> change_budget(attrs)
    |> Repo.insert()
    |> broadcast(:budget_created)
  end

  def delete_budget(budget_id) do
    find_budget(budget_id)
    |> Repo.delete()
    |> broadcast(:budget_deleted)
  end

  def update_budget(selected_budget, attrs \\ %{}) do
    selected_budget
    |> change_budget(attrs)
    |> Repo.update()
    |> broadcast(:budget_updated)
  end

  def list_budgets(%{user_id: user_id}, options) when is_map(options) do
    Queries.where_user(%{user_id: user_id})
    |> Queries.sort(options)
    |> Queries.paginate(options)
    |> Queries.records_for_month(options)
    |> Repo.all()
    |> Repo.preload(:category)
  end

  def list_budgets(%{user_id: user_id}) do
    Queries.where_user(%{user_id: user_id})
    |> Repo.all()
  end

  def find_budget(user_id, budget_id) do
    Repo.one(Queries.where_user_and_budget_ids%{user_id: user_id, budget_id: budget_id})
  end

  def find_budget(budget_id) do
    Repo.get(Budget, budget_id)
  end

  def change_budget(%Budget{} = budget, attr \\ %{}) do
    Budget.changeset(budget, attr)
  end

  def budgets_count do
    Repo.aggregate(Budget, :count, :id)
  end

  def get_total_budget_cost(params) do
    list_budgets(params)
    |> Enum.reduce(0, fn budget, acc -> acc + budget.cost end)
  end
end
