defmodule Ekmi.Repo.Migrations.AddPartnerRequestedToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :partner_requested, :boolean, default: false
      add :requested_email, :string
    end
  end
end
