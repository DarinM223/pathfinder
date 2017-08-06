defmodule PathfinderWeb.Repo.Migrations.AddShareidToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :shareid, :string, null: false
    end

    create unique_index(:games, [:shareid])
  end
end
