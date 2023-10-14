defmodule EkmiWeb.PageControllerTest do
  use EkmiWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert html_response(conn, 302) =~
             "<html><body>You are being <a href=\"/users/log_in\">redirected</a>.</body></html>"
  end
end
