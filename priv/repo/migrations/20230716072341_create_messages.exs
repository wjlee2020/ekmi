defmodule Ekmi.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :content, :string
      add :sender_id, references(:users, on_delete: :delete_all), null: false
      add :receiver_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:messages, [:sender_id])
    create index(:messages, [:receiver_id])
  end
end
