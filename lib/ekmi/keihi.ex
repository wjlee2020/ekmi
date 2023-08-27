defmodule Ekmi.Keihi do
  @moduledoc """
  Keihi Context module.
  """
  @moduledoc since: "1.0.0"

  alias Ekmi.Accounts.User
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

  @spec broadcast({:error, ecto_changeset} | {:ok, budget}, atom()) ::
          {:error, ecto_changeset} | {:ok, budget}
  def broadcast({:ok, budget}, tag) do
    Phoenix.PubSub.broadcast(
      @pubsub,
      @topic,
      {tag, budget}
    )

    {:ok, budget}
  end

  def broadcast({:error, _reason} = error, _tag), do: error

  @doc """
  Creates a new budget based on the provided attributes.

  ## Parameters
      - `attrs`: a map of attributes for the new budget. The keys should match the fields in the `Budget` schema.

  ## Returns
      - `{:ok, budget}`: if the budget was successfully created. `budget` will be a `Budget` struct representing the newly created budget.
      - `{:error, changeset}`: if there was an error creating the budget. `changeset` will be an `Ecto.Changeset` struct containing information about the errors.

  ## Examples
      iex> Ekmi.Keihi.create_budget(%{title: "Grocery", category_id: 1, cost: 50000, user_id: 1, created_at: ~D[2023-07-15], description: "Weekly Grocery"})
      {:ok, %Ekmi.Keihi.Budget{}}

  ## Note
    After a successful insert, a `:budget_created` event will be broadcasted for possible listeners in the system.
  """
  @spec create_budget(map()) :: {:ok, budget} | {:error, ecto_changeset}
  def create_budget(attrs \\ %{}) do
    %Budget{}
    |> change_budget(attrs)
    |> Repo.insert()
    |> broadcast(:budget_created)
  end

  @doc """
  Deletes a budget based on provided budget_id.

  ## Parameters
      - `budget_id`: integer associated with the ID of the budget.

  ## Returns
      - `{:ok, budget}`: if the budget was successfully deleted. `budget` will be a `Budget` struct representing the deleted budget.
      - `{:error, changeset}`: if there was an error creating the budget. `changeset` will be an `Ecto.Changeset` struct containing information about the errors.

  ## Examples
      iex> Ekmi.Keihi.delete_budget(1)
      {:ok, %Ekmi.Keihi.Budget{}}
  """
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

  @doc """
  Get all budgets with preloaded category with sorting, pagination, and filtering by month.

  ## Parameters
    - `user`: currently logged in user (or just a User struct).
    - `options`: a map that can contain keys for sorting (`:sort`), pagination (`:page`, `:page_size`),
    and filtering by month (`:year`, `:month`). The values for these keys should be appropriate for
    the `Queries.sort/2`, `Queries.paginate/2`, and `Queries.records_for_month/2` functions respectively.

  If `options` is not provided, then all budgets for the user are returned without any sorting, pagination, or filtering.

  ## Returns
      - A list of `Budget` structs for the given user, sorted, paginated, and filtered as per the `options` map (if provided).
      Each `Budget` struct will have its associated `:category` preloaded.

  ## Examples
      iex> Ekmi.Keihi.list_budgets(%User{id: 1}, %{sort: :desc, page: 1, page_size: 10, year: 2023, month: 7})
      [%Ekmi.Keihi.Budget{}]

      iex> Ekmi.Keihi.list_budgets(%User{id: 1})
      [%Ekmi.Keihi.Budget{}]
  """
  @spec list_budgets(%User{}, map()) :: [budget]
  def list_budgets(user = %User{}, options) when is_map(options) do
    Queries.where_user(user)
    |> Queries.sort(options)
    |> Queries.paginate(options)
    |> Queries.records_for_month(options)
    |> Repo.all()
  end

  @spec list_budgets(%User{}) :: [budget]
  def list_budgets(user = %User{}) do
    Queries.where_user(user)
    |> Repo.all()
  end

  @doc """
  Get a single budget struct based on user_id and the budget_id.

  ## Parameters
      - `user_id`: key associated with the ID of the user.
      - `budget_id`: key associated with the ID of the budget.

  ## Returns
      - A single budget struct either for the specific user or based on the budget struct id.

  If `user_id` is not provided, then it will only check for budget_id.

  ## Examples
      iex> Ekmi.Keihi.find_budget(1, 1)
      %Ekmi.Keihi.Budget{}

      iex> Ekmi.Keihi.find_budget(1)
      %Ekmi.Keihi.Budget{}
  """
  @spec find_budget(user_id, budget_id) :: budget | nil
  def find_budget(user_id, budget_id) do
    Repo.one(Queries.where_user_and_budget_ids(%{user_id: user_id, budget_id: budget_id}))
  end

  @spec find_budget(budget_id) :: budget | nil
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

  @doc """
  Calculates the total cost of all budgets for a given user.

  ## Parameters
    - `user`: User struct.

  ## Returns
    - An integer representing the total cost of all budgets for the provided user.

  ## Examples
      iex> Ekmi.Keihi.get_total_budget_cost(%User{id: 1})
      5000
  """
  @spec get_total_budget_cost(%User{}) :: integer()
  def get_total_budget_cost(user = %User{}) do
    list_budgets(user)
    |> Enum.reduce(0, fn budget, acc -> acc + budget.cost end)
  end

  @doc """
  Calculates the total cost of all budgets for a given user within specific options.

  ## Parameters
      - `user`: User struct.
      - `options`: a map that provides additional parameters for fetching the budgets. This could be sorting options, pagination options, etc.

  ## Returns
      - An integer representing the total cost of all budgets for the provided user within the given options.

  ## Examples
      iex> Ekmi.Keihi.get_total_budget_cost(%User{user: 1}, %{sort: :desc, page: 2})
      2500
  """
  @spec get_total_budget_cost(%User{}, map()) :: integer()
  def get_total_budget_cost(user = %User{}, options) do
    list_budgets(user, options)
    |> Enum.reduce(0, fn budget, acc -> acc + budget.cost end)
  end
end
