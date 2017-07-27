defmodule PathfinderWeb.Data.Change do
  use Ecto.Schema
  import Ecto.Changeset
  alias PathfinderWeb.Data.Change


  schema "changes" do
    field :args, :map
    field :name, :string
    field :type, :string
    belongs_to :game, PathfinderWeb.Data.Game
    belongs_to :user, PathfinderWeb.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(%Change{} = change, attrs) do
    change
    |> cast(attrs, [:name, :args, :type])
    |> validate_required([:name, :args, :type])
  end
end
