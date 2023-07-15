defmodule Ekmi.Keihi do
  @moduledoc"""
  Keihi Context module.
  """

  alias Ekmi.Keihi.{Budget, Queries}
  alias Ekmi.Repo

  @topic inspect(__MODULE__)
  @pubsub Ekmi.PubSub

  @type ecto_changeset :: Ecto.Changeset.t()
  @type budget :: %Budget{}
  @type options :: %{
    sort_by: atom(),
    sort_order: atom(),
    page: integer(),
    per_page: integer(),
    year: integer(),
    month: integer()
  }
  @type user_id :: integer()
  @type budget_id :: integer()

  @spec subscribe :: :ok | {:error, {:already_registered, pid}}
  def subscribe do
    Phoenix.PubSub.subscribe(@pubsub, @topic)
  end

  @spec broadcast({:error, ecto_changeset} | {:ok, budget}, atom()) :: {:error, ecto_changeset} | {:ok, budget}
  def broadcast({:ok, budget}, tag) do
    Phoenix.PubSub.broadcast(
      @pubsub,
      @topic,
      {tag, budget}
    )

    {:ok, budget}
  end

  def broadcast({:error, _reason} = error, _tag), do: error

  @spec create_budget(map()) :: {:ok, budget} | {:error, ecto_changeset}
  def create_budget(attrs \\ %{}) do
    %Budget{}
    |> change_budget(attrs)
    |> Repo.insert()
    |> broadcast(:budget_created)
  end

  @spec delete_budget(budget_id) :: {:ok, budget} | {:error, ecto_changeset}
  def delete_budget(budget_id) do
    find_budget(budget_id)
    |> Repo.delete()
    |> broadcast(:budget_deleted)
  end

  @spec update_budget(budget, map()) :: {:ok, budget} | {:error, ecto_changeset}
  def update_budget(selected_budget, attrs \\ %{}) do
    selected_budget
    |> change_budget(attrs)
    |> Repo.update()
    |> broadcast(:budget_updated)
  end

  @spec list_budgets(%{required(:user_id) => integer()}, options) :: [budget]
  def list_budgets(%{user_id: user_id}, options) when is_map(options) do
    Queries.where_user(%{user_id: user_id})
    |> Queries.sort(options)
    |> Queries.paginate(options)
    |> Queries.records_for_month(options)
    |> Repo.all()
    |> Repo.preload(:category)
  end

  @spec list_budgets(%{:user_id => integer()}) :: [budget]
  def list_budgets(%{user_id: user_id}) do
    Queries.where_user(%{user_id: user_id})
    |> Repo.all()
  end

  @spec find_budget(user_id, budget_id) :: budget | nil
  def find_budget(user_id, budget_id) do
    Repo.one(Queries.where_user_and_budget_ids%{user_id: user_id, budget_id: budget_id})
  end

  @spec find_budget(budget_id) :: budget
  def find_budget(budget_id) do
    Repo.get(Budget, budget_id)
  end

  @spec change_budget(budget, map()) :: ecto_changeset()
  def change_budget(%Budget{} = budget, attr \\ %{}) do
    Budget.changeset(budget, attr)
  end

  @spec budgets_count() :: integer()
  def budgets_count do
    Repo.aggregate(Budget, :count, :id)
  end

  @spec get_total_budget_cost(%{user_id: user_id}) :: integer()
  def get_total_budget_cost(params) do
    list_budgets(params)
    |> Enum.reduce(0, fn budget, acc -> acc + budget.cost end)
  end
end
