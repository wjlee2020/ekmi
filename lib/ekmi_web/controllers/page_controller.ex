defmodule EkmiWeb.PageController do
  use EkmiWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    case conn.assigns[:current_user] do
      nil ->
        redirect(conn, to: ~p"/users/log_in")
      _user ->
        redirect(conn, to: "/budgets")
    end
  end
end
