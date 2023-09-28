defmodule Ekmi.Repo.Migrations.UpdateBudgetTable do
  use Ecto.Migration

  def change do
    drop constraint(:budgets, "budgets_user_id_fkey")

    alter table(:budgets) do
      modify :user_id, references(:users, on_delete: :delete_all)
    end
  end
end
