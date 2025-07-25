defmodule PathfinderWeb.Web.UserSocket do
  use Phoenix.Socket

  require Logger

  @max_age 86400

  ## Channels
  # channel "room:*", PathfinderWeb.Web.RoomChannel
  channel("games:*", PathfinderWeb.Web.GameChannel)

  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(%{"token" => token}, socket) do
    Logger.info("Verifying token: #{inspect(token)}")

    case Phoenix.Token.verify(socket, "user socket", token, max_age: @max_age) do
      {:ok, user_id} ->
        {:ok, assign(socket, :user_id, user_id)}

      {:error, _reason} ->
        case Phoenix.Token.verify(socket, "non-logged-in-user socket", token, max_age: @max_age) do
          {:ok, _} ->
            {:ok, assign(socket, :user_id, -1)}

          {:error, _reason} ->
            case Phoenix.Token.verify(PathfinderWeb.Web.Endpoint, "bot", token, max_age: @max_age) do
              {:ok, _} ->
                {:ok, assign(socket, :user_id, -2)}

              {:error, _reason} ->
                :error
            end
        end
    end
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     PathfinderWeb.Web.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(socket), do: "users_socket:#{socket.assigns.user_id}"
end
