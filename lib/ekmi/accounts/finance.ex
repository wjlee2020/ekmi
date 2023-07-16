defmodule Ekmi.Accounts.Finance do
  use Ecto.Schema
  import Ecto.Changeset

  schema "finances" do
    field :balance, :integer, default: 200000
    field :currency, :string
    belongs_to :user, Ekmi.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(finance, attrs) do
    finance
    |> cast(attrs, [:balance, :currency, :user_id])
    |> validate_required([:balance, :currency, :user_id])
    |> validate_length(:currency, min: 3, max: 3)
    |> foreign_key_constraint(:user_id)
  end
end
