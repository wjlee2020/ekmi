defmodule Ekmi.Accounts.Account do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :name, :string
    field :partner_requested, :boolean, default: false
    field :has_partner, :boolean, default: false
    field :requested_email, :string
    field :requested_by, :string

    belongs_to :user, Ekmi.Accounts.User
    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :has_partner, :requested_email, :requested_by, :user_id])
    |> validate_required([:name, :has_partner])
  end

  def register_account_changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
  end
end
