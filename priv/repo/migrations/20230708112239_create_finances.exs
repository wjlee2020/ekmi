defmodule Ekmi.Repo.Migrations.CreateFinances do
  use Ecto.Migration

  def change do
    create table(:finances) do
      add :balance, :integer, default: 0
      add :currency, :string, default: "JYP"
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:finances, [:user_id])
  end
end
