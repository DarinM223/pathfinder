defmodule PathfinderWeb.Data.Game do
  use Ecto.Schema
  import Ecto.Changeset
  alias PathfinderWeb.Data.Game


  schema "games" do
    belongs_to :user, PathfinderWeb.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(%Game{} = game, attrs) do
    game
    |> cast(attrs, [])
    |> validate_required([])
  end
end
