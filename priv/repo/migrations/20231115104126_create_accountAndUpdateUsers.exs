defmodule Ekmi.Repo.Migrations.CreateAccount do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :name, :string
      add :partner_requested, :boolean, default: false
      add :has_partner, :boolean, default: false
      add :requested_email, :string
      add :requested_by, :string

      timestamps()
    end

    create index(:accounts, [:user_id])
  end
end
