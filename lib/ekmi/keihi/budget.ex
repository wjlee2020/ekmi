defmodule Ekmi.Keihi.Budget do
  use Ecto.Schema
  import Ecto.Changeset

  schema "budgets" do
    field :description, :string
    field :title, :string
    field :cost, :integer
    field :user_id, :id
    field :created_at, :date
    field :receipt_img, {:array, :string}, default: []

    belongs_to :category, Ekmi.Keihi.Category

    timestamps()
  end

  @doc false
  def changeset(budget, attrs) do
    budget
    |> cast(attrs, [
      :title,
      :description,
      :cost,
      :category_id,
      :user_id,
      :created_at,
      :receipt_img
    ])
    |> validate_required([:title, :description, :cost, :category_id, :user_id, :created_at])
    |> foreign_key_constraint(:category_id)
    |> foreign_key_constraint(:user_id)
  end
end
