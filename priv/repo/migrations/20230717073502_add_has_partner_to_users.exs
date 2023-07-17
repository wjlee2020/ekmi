defmodule Ekmi.Repo.Migrations.AddHasPartnerToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :has_partner, :boolean
    end
  end
end
