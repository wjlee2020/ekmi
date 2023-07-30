defmodule EkmiWeb.MessagesInputComponent do
  use EkmiWeb, :live_component

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col">
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
    </div>
    """
  end
end
