defmodule PathfinderWeb.Repo.Migrations.AddOtherUserIdToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :other_user_id, :integer, default: -1
    end
  end
end
