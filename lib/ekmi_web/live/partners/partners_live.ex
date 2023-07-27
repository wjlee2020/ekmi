defmodule EkmiWeb.PartnersLive do
  use EkmiWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div></div>
    """
  end
end
