defmodule PathfinderWeb.Repo.Migrations.AddOtherUserNameToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :other_user_name, :string, default: nil
    end
  end
end
