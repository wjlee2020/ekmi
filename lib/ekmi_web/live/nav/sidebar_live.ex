defmodule EkmiWeb.Nav.SidebarLive do
  use EkmiWeb, :live_component

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <span>Side bar</span>
      <span>Todo</span>
    </div>
    """
  end
end
