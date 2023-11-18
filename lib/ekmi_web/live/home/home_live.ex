defmodule EkmiWeb.HomeLive do
  @moduledoc """
  Home Live
  """

  use EkmiWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>home</h1>
    """
  end
end
