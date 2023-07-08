defmodule Ekmi.Keihi.Budget do
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
    |> validate_required([:title, :description, :category_id, :user_id])
    |> foreign_key_constraint(:category_id)
    |> foreign_key_constraint(:user_id)
  end
end
