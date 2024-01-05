defmodule Ekmi.Accounts.Account do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :name, :string
    field :email, :string
    field :partner_requested, :boolean, default: false
    field :has_partner, :boolean, default: false
    field :requested_email, :string
    field :requested_by, :string

    belongs_to :user, Ekmi.Accounts.User
    has_one :finance, Ekmi.Accounts.Finance
    has_one :partner_relation, Ekmi.Accounts.Partner
    has_many :budgets, Ekmi.Keihi.Budget

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [
      :name,
      :email,
      :has_partner,
      :partner_requested,
      :requested_email,
      :requested_by,
      :user_id
    ])
    |> validate_required([:name, :has_partner])
  end

  def name_changeset(user, attrs) do
    user
    |> cast(attrs, [:name])
    |> validate_length(:name, min: 3)
  end

  def register_account_changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
  end

  def requested_partner_changeset(account, attrs) do
    account
    |> cast(attrs, [:partner_requested, :requested_email, :requested_by])
    |> validate_required([:partner_requested, :requested_email, :requested_by])
  end

  def update_partner_changeset(account, attrs) do
    account
    |> cast(attrs, [:has_partner])
    |> validate_required([:has_partner])
  end

  def delete_partner_changeset(account, attrs) do
    account
    |> cast(attrs, [:has_partner, :partner_requested, :requested_email, :requested_by])
  end
end
