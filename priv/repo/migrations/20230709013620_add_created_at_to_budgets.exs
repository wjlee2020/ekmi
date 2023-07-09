defmodule Ekmi.Repo.Migrations.AddCreatedAtToBudgets do
  use Ecto.Migration

  def change do
    alter table(:budgets) do
      add :created_at, :date
    end
  end
end
