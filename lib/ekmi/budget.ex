defmodule Ekmi.Budget do
  use Ecto.Schema
  import Ecto.Changeset

  schema "budgets" do
    field :description, :string
    field :title, :string
    field :user_id, :id
    field :category_id, :id

    timestamps()
  end

  @doc false
  def changeset(budget, attrs) do
    budget
    |> cast(attrs, [:title, :description])
    |> validate_required([:title, :description])
  end
end
