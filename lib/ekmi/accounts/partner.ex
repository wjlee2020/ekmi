defmodule Ekmi.Accounts.Partner do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "partners" do
    field :balance, :integer
    belongs_to :account, Ekmi.Accounts.Account, foreign_key: :account_id
    belongs_to :partner_account, Ekmi.Accounts.Account, foreign_key: :partner_account_id

    timestamps()
  end

  def changeset(partner, attrs) do
    partner
    |> cast(attrs, [:user_id, :partner_id, :balance])
    |> validate_required([:user_id, :partner_id, :balance])
    |> assoc_constraint(:user)
    |> foreign_key_constraint(:partner_id)
  end

  def partner_balance_changeset(partner, attrs) do
    partner
    |> cast(attrs, [:balance])
    |> validate_required([:balance])
  end
end
