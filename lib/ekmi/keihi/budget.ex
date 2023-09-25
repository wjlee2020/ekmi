defmodule Ekmi.Keihi.Budget do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "budgets" do
    field :description, :string
    field :title, :string
    field :cost, :integer
    field :created_at, :date
    field :receipt_img, {:array, :string}, default: []

    belongs_to :category, Ekmi.Keihi.Category
    belongs_to :user, Ekmi.Accounts.User

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
    |> assoc_constraint(:user)
    |> foreign_key_constraint(:category_id)
  end

  def update_changeset(budget, attrs) do
    initial_changeset =
      budget
      |> cast(attrs, [
        :title,
        :description,
        :cost,
        :category_id,
        :created_at,
        :receipt_img
      ])
      |> validate_required([:title, :description, :cost, :category_id, :created_at])
      |> assoc_constraint(:user)
      |> foreign_key_constraint(:category_id)

    attrs_recipt_img = attrs["receipt_img"] || []
    current_images = get_field(initial_changeset, :receipt_img) || []
    combined_images = current_images ++ attrs_recipt_img || []

    put_change(initial_changeset, :receipt_img, Enum.uniq(combined_images))
  end
end
