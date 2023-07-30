defmodule EkmiWeb.MessagesLive do
  use EkmiWeb, :live_view

  alias Ekmi.{Accounts, Chat}
  alias Ekmi.Chat.Message
  alias Ekmi.Repo
  alias EkmiWeb.{MessagesInputComponent, Presence}

  @topic "users:chatroom"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{current_user: current_user} = socket.assigns

    if connected?(socket) do
      Chat.subscribe()

      {:ok, _ref} = Presence.track(self(), @topic, current_user.id, %{
        username: Accounts.current_username(current_user),
        is_typing: false,
      })
    end

    presences = simple_presence_map(Presence.list(@topic))

    changset = Chat.change_message(%Message{})
    messages = Chat.list_messages()

    socket =
      socket
      |> stream(:messages, messages)
      |> assign(:message_form, to_form(changset))
      |> assign(:sender_id, current_user.id)
      |> assign(:receiver_id, nil)
      |> assign(:presences, presences)
      |> assign(:is_typing, false)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-3">
      <ul>
        online

        <li :for={{_user_id, meta} <- @presences}>
          <span>
            🟢
          </span>
          <span>
            <%= meta.username %>
          </span>
        </li>
      </ul>

      <div class="h-[30rem] grid col-span-2 p-6 border rounded-lg shadow bg-gray-800 border-gray-700">
        <div
          id="messages"
          phx-update="stream"
          phx-hook="ScrollDown"
          class="flex flex-col gap-4 overflow-scroll"
          data-scrolled-to-top="false"
        >
          <div
            :for={{message_id, message} <- @streams.messages}
            id={message_id}
            class="mb-4"
            style={"align-self: #{message_align(%{sender_email: message.sender.email, current_user_email: assigns.current_user.email})}"}
          >
            <div
              class="flex flex-col p-4 rounded-lg"
              style={"background-color: #{message_style(%{sender_email: message.sender.email, current_user_email: assigns.current_user.email})}"}
            >
              <span>
                <%= message.content %>
              </span>
            </div>
          </div>
        </div>

        <.live_component
          module={MessagesInputComponent}
          id={:new}
          message_form={@message_form}
          sender_id={@sender_id}
          receiver_id={@receiver_id}
        />
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"message" => message}, socket) do
    socket = update(socket, :is_typing, fn _ -> true end)

    %{current_user: current_user} = socket.assigns
    %{metas: [meta | _]} = Presence.get_by_key(@topic, current_user.id)
    new_meta = %{meta | is_typing: socket.assigns.is_typing}

    message_form =
      %Message{}
      |> Chat.change_message(message)
      |> Map.put(:action, :validate)
      |> to_form()

    Presence.update(self(), @topic, current_user.id, new_meta)

    {:noreply, assign(socket, message_form: message_form)}
  end

  def handle_event("send", %{"message" => message}, socket) do
    case Chat.create_message(message) do
      {:ok, _message} ->
        {:noreply, socket}

      {:error, changeset} ->
        message_form =
          changeset
          |> Map.put(:action, :validate)
          |> to_form()

        socket =
          socket
          |> put_flash(:error, "Failed to send message")
          |> assign(message_form: message_form)

        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:message_sent, message}, socket) do
    message_form =
      %Message{}
      |> Chat.change_message()
      |> to_form()

    message = Repo.preload(message, [:sender, :receiver])

    socket =
      socket
      |> stream_insert(:messages, message, at: -1)
      |> assign(message_form: message_form)

    {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    socket =
      socket
      |> remove_presences(diff.leaves)
      |> add_presences(diff.joins)

    {:noreply, socket}
  end

  defp simple_presence_map(presences) do
    Enum.into(presences, %{}, fn {user_id, %{metas: [meta | _]}} ->
      {user_id, meta}
    end)
  end

  defp remove_presences(socket, leaves) do
    user_ids = Enum.map(leaves, fn {user_id, _meta} -> user_id end)
    presences = Map.drop(socket.assigns.presences, user_ids)
    assign(socket, :presences, presences)
  end

  defp add_presences(socket, joins) do
    presences = Map.merge(socket.assigns.presences, simple_presence_map(joins))

    socket = Map.filter(presences, fn {key, _v} -> key !== Integer.to_string(socket.assigns.current_user.id) end)
    |> Map.keys
    |> add_receiver(socket)

    assign(socket, :presences, presences)
  end

  defp add_receiver(_keys = [], socket), do: socket
  defp add_receiver(keys, socket), do: assign(socket, :receiver_id, String.to_integer(hd(keys)))

  defp message_align(%{sender_email: sender_email, current_user_email: current_user_email}) do
    cond do
      sender_email == current_user_email -> "end"
      true -> "start"
    end
  end

  defp message_style(%{sender_email: sender_email, current_user_email: current_user_email}) do
    cond do
      sender_email == current_user_email -> "white"
      true -> "#8DA2FB"
    end
  end
end
