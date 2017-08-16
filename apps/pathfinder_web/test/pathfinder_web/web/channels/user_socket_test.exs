defmodule PathfinderWeb.Web.UserSocketTest do
  use PathfinderWeb.Web.ChannelCase, async: true

  alias PathfinderWeb.Web.UserSocket
  alias Phoenix.Token

  test "socket authentication with user token" do
    token = Token.sign(@endpoint, "user socket", "123")

    assert {:ok, socket} = connect(UserSocket, %{"token" => token})
    assert socket.assigns.user_id == "123"
  end

  test "socket authentication with non-logged-in user token" do
    token = Token.sign(@endpoint, "non-logged-in-user socket", "123")

    assert {:ok, socket} = connect(UserSocket, %{"token" => token})
    assert socket.assigns.user_id == -1
  end

  test "socket authentication with invalid token" do
    assert :error = connect(UserSocket, %{"token" => "1313"})
  end
end
