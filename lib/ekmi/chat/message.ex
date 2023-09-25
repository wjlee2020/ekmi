defmodule Ekmi.Chat.Message do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :content, :string
    belongs_to :sender, Ekmi.Accounts.User
    belongs_to :receiver, Ekmi.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :sender_id, :receiver_id])
    |> foreign_key_constraint(:sender_id)
    |> foreign_key_constraint(:receiver_id)
  end
end
