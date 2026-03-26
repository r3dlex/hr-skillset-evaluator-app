defmodule SkillsetEvaluator.Repo.Migrations.CreateEvaluations do
  use Ecto.Migration

  def change do
    create table(:evaluations) do
      add :manager_score, :integer
      add :self_score, :integer
      add :period, :string, null: false
      add :notes, :text
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :skill_id, references(:skills, on_delete: :delete_all), null: false
      add :evaluated_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:evaluations, [:user_id])
    create index(:evaluations, [:skill_id])
    create index(:evaluations, [:evaluated_by_id])
    create unique_index(:evaluations, [:user_id, :skill_id, :period])
  end
end
