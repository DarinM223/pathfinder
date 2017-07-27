defmodule PathfinderWeb.Repo.Migrations.CreatePathfinderWeb.Data.Change do
  use Ecto.Migration

  def change do
    create table(:changes) do
      add :name, :string
      add :args, :map
      add :type, :string
      add :game_id, references(:games, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:changes, [:game_id])
    create index(:changes, [:user_id])
  end
end
