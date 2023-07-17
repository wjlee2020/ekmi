defmodule Ekmi.Repo.Migrations.CreatePartners do
  use Ecto.Migration

  def change do
    create table(:partners) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :partner_id, references(:users, on_delete: :delete_all)
      add :balance, :integer, default: 0

      timestamps()
    end

    create unique_index(:partners, [:user_id])
    create unique_index(:partners, [:partner_id])
  end
end
