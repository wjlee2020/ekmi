defmodule Ekmi.Chat do
  @moduledoc false

  import Ecto.Query

  alias Ekmi.Chat.Message
  alias Ekmi.Repo

  def list_messages(sender_id) do
    query = from(m in Message,
    where: m.sender_id == ^sender_id
  )

    Repo.all(query)
  end

  def list_messages() do
    Repo.all(Message)
    |> Repo.preload([:sender, :receiver])
  end

  def create_message(attrs \\ %{}) do
    %Message{}
    |> change_message(attrs)
    |> Repo.insert()
  end

  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  def update_message(%Message{} = message, attrs \\ %{}) do
    message
    |> change_message(attrs)
    |> Repo.update()
  end

  def change_message(%Message{} = message, attr \\ %{}) do
    message
    |> Message.changeset(attr)
  end
end
