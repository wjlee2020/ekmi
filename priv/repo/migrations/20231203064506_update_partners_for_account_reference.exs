defmodule Ekmi.Repo.Migrations.UpdatePartnersForAccountReference do
  use Ecto.Migration

  def change do
    alter table(:partners) do
      add :account_id, references(:accounts, on_delete: :delete_all)
      add :partner_account_id, references(:accounts, on_delete: :delete_all)
    end

    # Populate new columns based on the existing user_id and partner_id
    execute "UPDATE partners SET account_id = (SELECT id FROM accounts WHERE accounts.user_id = partners.user_id)"

    execute "UPDATE partners SET partner_account_id = (SELECT id FROM accounts WHERE accounts.user_id = partners.partner_id)"

    # Remove old columns
    alter table(:partners) do
      remove :user_id
      remove :partner_id
    end

    # Update indexes
    drop_if_exists unique_index(:partners, [:user_id])
    drop_if_exists unique_index(:partners, [:partner_id])
    create unique_index(:partners, [:account_id])
    create unique_index(:partners, [:partner_account_id])
  end
end
