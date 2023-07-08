defmodule Ekmi.Repo.Migrations.CreateBudgets do
  use Ecto.Migration

  def change do
    create table(:budgets) do
      add :title, :string
      add :description, :text
      add :user_id, references(:users, on_delete: :nothing)
      add :category_id, references(:categories, on_delete: :nothing)

      timestamps()
    end

    create index(:budgets, [:user_id])
    create index(:budgets, [:category_id])
  end
end
