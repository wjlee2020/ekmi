defmodule EkmiWeb.MessagesInputComponent do
  @moduledoc false

  use EkmiWeb, :live_component

  alias EkmiWeb.SVGs

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
            <SVGs.messenger_upload id="messenger_upload" />

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
            disabled={!@receiver_id}
          />

          <.input type="hidden" field={@message_form[:sender_id]} value={@sender_id} />
          <.input type="hidden" field={@message_form[:receiver_id]} value={@receiver_id} />

          <button
            disabled={!@receiver_id}
            type="submit"
            class="inline-flex justify-center p-2 rounded-full cursor-pointer text-blue-500 hover:bg-gray-600"
          >
            <SVGs.send_message id="send_message" />
            <span class="sr-only">Send message</span>
          </button>
        </div>
      </.form>
    </div>
    """
  end
end
