defmodule EkmiWeb.MessagesLive do
  use EkmiWeb, :live_view

  alias Ekmi.{Accounts, Chat}
  alias Ekmi.Chat.Message
  alias Ekmi.Repo
  alias EkmiWeb.Presence

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
      |> assign(:receiver_id, 1)
      |> assign(:presences, presences)
      |> assign(:is_typing, false)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <ul>
        <li :for={{_user_id, meta} <- @presences}>
          <span>
            <%= if meta.is_typing, do: "#{meta.username} is typing...", else: "😀" %>
          </span>
          <span>
            <%= meta.username %>
          </span>
        </li>
      </ul>

      <div class="h-[30rem] grid p-6 border rounded-lg shadow bg-gray-800 border-gray-700">
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

        <.message_input message_form={@message_form} sender_id={@sender_id} receiver_id={@receiver_id} />
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

  def message_input(assigns) do
    ~H"""
    <.form for={@message_form} phx-change="validate" phx-submit="send" style="margin-top: auto;">
      <label for="chat" class="sr-only">Your message</label>
      <div class="flex items-center px-3 py-2 rounded-lg bg-gray-700">
        <button
          type="button"
          class="inline-flex justify-center p-2 rounded-lg cursor-pointer text-gray-400 hover:text-white hover:bg-gray-600"
        >
          <svg
            class="w-5 h-5"
            aria-hidden="true"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 20 18"
          >
            <path
              fill="currentColor"
              d="M13 5.5a.5.5 0 1 1-1 0 .5.5 0 0 1 1 0ZM7.565 7.423 4.5 14h11.518l-2.516-3.71L11 13 7.565 7.423Z"
            />
            <path
              stroke="currentColor"
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M18 1H2a1 1 0 0 0-1 1v14a1 1 0 0 0 1 1h16a1 1 0 0 0 1-1V2a1 1 0 0 0-1-1Z"
            />
            <path
              stroke="currentColor"
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M13 5.5a.5.5 0 1 1-1 0 .5.5 0 0 1 1 0ZM7.565 7.423 4.5 14h11.518l-2.516-3.71L11 13 7.565 7.423Z"
            />
          </svg>
          <span class="sr-only">Upload image</span>
        </button>

        <.input
          field={@message_form[:content]}
          type="textarea"
          id="chat"
          rows="1"
          placeholder="Send a message"
          autocomplete="off"
          style="min-height: auto; width: 95%; margin: 12px auto;"
        />

        <.input type="hidden" field={@message_form[:sender_id]} value={@sender_id} />
        <.input type="hidden" field={@message_form[:receiver_id]} value={@receiver_id} />

        <button
          type="submit"
          class="inline-flex justify-center p-2 rounded-full cursor-pointer text-blue-500 hover:bg-gray-600"
        >
          <svg
            class="w-5 h-5 rotate-90"
            aria-hidden="true"
            xmlns="http://www.w3.org/2000/svg"
            fill="currentColor"
            viewBox="0 0 18 20"
          >
            <path d="m17.914 18.594-8-18a1 1 0 0 0-1.828 0l-8 18a1 1 0 0 0 1.157 1.376L8 18.281V9a1 1 0 0 1 2 0v9.281l6.758 1.689a1 1 0 0 0 1.156-1.376Z" />
          </svg>
          <span class="sr-only">Send message</span>
        </button>
      </div>
    </.form>
    """
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
    assign(socket, :presences, presences)
  end

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
