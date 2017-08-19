defmodule PathfinderWeb.Data.Change do
  use Ecto.Schema
  import Ecto.Changeset
  alias PathfinderWeb.Data.Change


  schema "changes" do
    field :args, :map
    field :name, :string
    field :type, :string
    field :user_id, :integer
    belongs_to :game, PathfinderWeb.Data.Game

    timestamps()
  end

  @doc false
  def changeset(%Change{} = change, attrs) do
    change
    |> cast(attrs, [:name, :args, :user_id])
    |> validate_required([:name, :args, :user_id])
  end
end
