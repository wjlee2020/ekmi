defmodule EkmiWeb.BudgetsLive do
  use EkmiWeb, :live_view

  alias Ekmi.Keihi

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    budgets = Keihi.list_budgets(%{user_id: socket.assigns.current_user.id})
    socket = assign(socket, budgets: budgets)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Budgets</h1>

    <div :for={budget <- @budgets}>
      <span>
        <%= budget.title %>
      </span>

      <span>
        <%= budget.description %>
      </span>
    </div>
    """
  end
end
