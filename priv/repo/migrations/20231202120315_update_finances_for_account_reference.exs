defmodule Ekmi.Repo.Migrations.UpdateFinancesForAccountReference do
  use Ecto.Migration

  def change do
    alter table(:finances) do
      add :account_id, references(:accounts, on_delete: :delete_all)
    end

    # Ensure that you have a matching account for each user in finances
    execute "UPDATE finances SET account_id = (SELECT id FROM accounts WHERE accounts.user_id = finances.user_id)"

    # After updating account_id, remove the user_id column
    alter table(:finances) do
      remove :user_id
    end

    # Update the unique index
    drop_if_exists unique_index(:finances, [:user_id])
    create unique_index(:finances, [:account_id])
  end
end
