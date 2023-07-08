defmodule EkmiWeb.BudgetsLive do
  use EkmiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Budgets</h1>

    <div>hello</div>
    """
  end
end
