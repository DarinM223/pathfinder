defmodule PathfinderWeb.Data.Game do
  use Ecto.Schema
  import Ecto.Changeset
  alias PathfinderWeb.Accounts.User
  alias PathfinderWeb.Data.Game
  alias PathfinderWeb.Repo

  schema "games" do
    belongs_to(:user, PathfinderWeb.Accounts.User)
    has_many(:changes, PathfinderWeb.Data.Change, on_delete: :delete_all)
    field(:other_user_id, :integer)
    field(:shareid, :string)
    field(:accessed, :boolean, default: false)
    field(:winner, :integer, default: nil)
    field(:other_user_name, :string)
    field(:other_user_type, :string, virtual: true)

    timestamps()
  end

  @doc false
  def changeset(%Game{} = game, attrs) do
    game
    |> cast(attrs, [:accessed, :winner])
    |> validate_required([])
    |> validate_winner()
  end

  def create_changeset(%Game{} = game, user_id, attrs) do
    game
    |> cast(attrs, [:other_user_type, :other_user_name])
    |> validate_required([:other_user_type, :other_user_name])
    |> validate_length(:other_user_name, min: 1, max: 20)
    |> validate_other_user_name()
    |> validate_different_ids(user_id)
    |> put_change(:shareid, Ecto.UUID.generate())
  end

  # Validates that the winner is one of the players in the game.
  defp validate_winner(%{changes: changes, data: data, valid?: true} = changeset) do
    if changes[:winner] == data.user_id or changes[:winner] == data.other_user_id or
         changes[:winner] == nil do
      changeset
    else
      add_error(changeset, :winner, "must be a player in the game")
    end
  end

  defp validate_winner(changeset), do: changeset

  # Validates that if it is an existing user,
  # the user with that name exists in the database.
  defp validate_other_user_name(%{changes: changes, valid?: true} = changeset) do
    other_user_type = changes[:other_user_type]
    other_user_name = changes[:other_user_name]

    case other_user_type do
      "existing" ->
        user = Repo.get_by(User, username: other_user_name)

        if user == nil do
          add_error(changeset, :other_user_name, "must be a valid user")
        else
          changeset
          |> put_change(:other_user_id, user.id)
          |> put_change(:other_user_name, user.username)
        end

      "nonexisting" ->
        put_change(changeset, :other_user_id, -1)

      "bot" ->
        put_change(changeset, :other_user_id, -2)

      _ ->
        add_error(changeset, :other_user_type, "must be a valid type")
    end
  end

  defp validate_other_user_name(changeset), do: changeset

  # Validates that the ids of the two users are not the same.
  defp validate_different_ids(%{changes: changes, valid?: true} = changeset, user_id) do
    if changes[:other_user_id] == user_id do
      add_error(changeset, :other_user_name, "users must be different")
    else
      changeset
    end
  end

  defp validate_different_ids(changeset, _user_id), do: changeset
end
