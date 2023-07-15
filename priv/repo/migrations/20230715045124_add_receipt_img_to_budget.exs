defmodule Ekmi.Repo.Migrations.AddReceiptImgToBudget do
  use Ecto.Migration

  def change do
    alter table(:budgets) do
      add :receipt_img, {:array, :string}, null: false, default: []
    end
  end
end
