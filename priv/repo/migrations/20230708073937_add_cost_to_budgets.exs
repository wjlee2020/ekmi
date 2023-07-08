defmodule Ekmi.Repo.Migrations.AddCostToBudgets do
  use Ecto.Migration

  def change do
    alter table(:budgets) do
      add :cost, :integer
    end
  end
end
