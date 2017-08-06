defmodule PathfinderWeb.Data.Game do
  use Ecto.Schema
  import Ecto.Changeset
  alias PathfinderWeb.Data.Game


  schema "games" do
    belongs_to :user, PathfinderWeb.Accounts.User
    field :other_user_id, :integer
    field :shareid, :string

    timestamps()
  end

  @doc false
  def changeset(%Game{} = game, attrs) do
    game
    |> cast(attrs, [])
    |> validate_required([])
  end

  def create_changeset(%Game{} = game, attrs) do
    game
    |> changeset(attrs)
    |> put_change(:shareid, Ecto.UUID.generate())
  end
end
