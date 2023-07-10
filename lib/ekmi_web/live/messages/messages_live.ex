defmodule EkmiWeb.MessagesLive do
  use EkmiWeb, :live_view

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>Messages</div>
    """
  end
end
