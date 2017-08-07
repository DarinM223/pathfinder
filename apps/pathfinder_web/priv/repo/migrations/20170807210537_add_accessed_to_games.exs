defmodule PathfinderWeb.Repo.Migrations.AddAccessedToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :accessed, :boolean, default: false
    end
  end
end
