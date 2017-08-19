defmodule PathfinderWeb.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias PathfinderWeb.Accounts.User


  schema "users" do
    field :name, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_confirm, :string, virtual: true
    field :password_hash, :string
    has_many :games, PathfinderWeb.Data.Game

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :username])
    |> validate_required([:name, :username])
    |> validate_length(:username, min: 1, max: 20)
    |> unique_constraint(:username)
  end

  def registration_changeset(%User{} = user, attrs) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:password, :password_confirm])
    |> validate_required([:password, :password_confirm])
    |> validate_length(:password, min: 6, max: 100)
    |> validate_password_confirm()
    |> put_password_hash()
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(password))
      _ ->
        changeset
    end
  end

  defp validate_password_confirm(%{changes: changes, valid?: true} = changeset) do
    password = changes[:password]
    case changes[:password_confirm] do
      ^password -> changeset
      _ -> add_error(changeset, :password_confirm, "must match password")
    end
  end
  defp validate_password_confirm(changeset), do: changeset
end
