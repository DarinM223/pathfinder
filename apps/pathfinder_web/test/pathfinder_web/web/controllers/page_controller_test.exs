defmodule PathfinderWeb.Web.PageControllerTest do
  use PathfinderWeb.Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Pathfinder"
  end
end
