defmodule Ekmi.Chat do
  @moduledoc false

  import Ecto.Query

  alias Ekmi.Chat.Message
  alias Ekmi.Repo

  @topic inspect(__MODULE__)
  @pubsub Ekmi.PubSub
  @type ecto_changeset :: Ecto.Changeset.t()
  @type message :: %Message{}

  @spec subscribe :: :ok | {:error, {:already_registered, pid}}
  def subscribe do
    Phoenix.PubSub.subscribe(@pubsub, @topic)
  end

  @spec broadcast({:error, ecto_changeset} | {:ok, message}, atom()) ::
          {:error, ecto_changeset} | {:ok, message}
  def broadcast({:ok, message}, tag) do
    Phoenix.PubSub.broadcast(
      @pubsub,
      @topic,
      {tag, message}
    )

    {:ok, message}
  end

  def broadcast({:error, _reason} = error, _tag), do: error

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
    |> broadcast(:message_sent)
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
