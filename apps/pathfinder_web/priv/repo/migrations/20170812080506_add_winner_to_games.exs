defmodule PathfinderWeb.Repo.Migrations.AddWinnerToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :winner, :integer, null: true
    end
  end
end
