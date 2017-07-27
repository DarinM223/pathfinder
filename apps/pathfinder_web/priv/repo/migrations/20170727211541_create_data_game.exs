defmodule PathfinderWeb.Repo.Migrations.CreatePathfinderWeb.Data.Game do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:games, [:user_id])
  end
end
