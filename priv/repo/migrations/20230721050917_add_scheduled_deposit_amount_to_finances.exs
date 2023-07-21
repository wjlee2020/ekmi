defmodule Ekmi.Repo.Migrations.AddScheduledDepositAmountToFinances do
  use Ecto.Migration

  def change do
    alter table(:finances) do
      add :scheduled_deposit_amount, :integer
    end
  end
end
