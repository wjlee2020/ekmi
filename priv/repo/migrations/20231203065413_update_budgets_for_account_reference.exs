defmodule Ekmi.Repo.Migrations.UpdateBudgetsForAccountReference do
  use Ecto.Migration

  def change do
    alter table(:budgets) do
      add :account_id, references(:accounts, on_delete: :delete_all)
    end

    execute "UPDATE budgets SET account_id = (SELECT id FROM accounts WHERE accounts.user_id = budgets.user_id)"

    alter table(:budgets) do
      remove :user_id
    end

    drop_if_exists unique_index(:budgets, [:user_id])
    drop_if_exists index(:budgets, [:user_id])
    create index(:budgets, [:account_id])
  end
end
