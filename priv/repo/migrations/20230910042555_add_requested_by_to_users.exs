defmodule Ekmi.Repo.Migrations.AddRequestedByToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :requested_by, :string
    end
  end
end
