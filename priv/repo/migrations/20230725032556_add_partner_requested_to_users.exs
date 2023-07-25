defmodule Ekmi.Repo.Migrations.AddPartnerRequestedToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :partner_requested, :boolean, default: false
    end
  end
end
