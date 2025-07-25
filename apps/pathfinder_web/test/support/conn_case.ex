defmodule PathfinderWeb.Web.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use PathfinderWeb.Web, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import PathfinderWeb.Web.Router.Helpers
      import PathfinderWeb.TestHelpers

      # The default endpoint for testing
      @endpoint PathfinderWeb.Web.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PathfinderWeb.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(PathfinderWeb.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
