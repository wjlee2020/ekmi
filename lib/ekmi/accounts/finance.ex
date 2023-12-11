defmodule Ekmi.Accounts.Finance do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: ~w(balance currency scheduled_deposit_amount)a}

  schema "finances" do
    field :balance, :integer, default: 200_000
    field :currency, :string
    field :scheduled_deposit_amount, :integer
    belongs_to :account, Ekmi.Accounts.Account

    timestamps()
  end

  @doc false
  def changeset(finance, attrs) do
    finance
    |> cast(attrs, [:balance, :currency, :scheduled_deposit_amount, :account_id])
    |> validate_required([:balance, :currency, :scheduled_deposit_amount, :account_id])
    |> validate_length(:currency, min: 3, max: 3)
    |> foreign_key_constraint(:account_id)
  end

  def balance_changeset(finance, attrs) do
    finance
    |> cast(attrs, [:balance])
    |> validate_required([:balance])
  end

  def deposit_amount_changeset(finance, attrs) do
    finance
    |> cast(attrs, [:scheduled_deposit_amount])
    |> validate_required([:scheduled_deposit_amount])
  end
end
