defmodule SkillsetEvaluator.Repo.Migrations.CreateUserTeams do
  use Ecto.Migration

  def change do
    create table(:user_teams) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :team_id, references(:teams, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_teams, [:user_id, :team_id])
    create index(:user_teams, [:team_id])
  end
end
