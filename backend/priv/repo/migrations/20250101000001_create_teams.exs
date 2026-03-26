defmodule SkillsetEvaluator.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:teams, [:name])
  end
end
