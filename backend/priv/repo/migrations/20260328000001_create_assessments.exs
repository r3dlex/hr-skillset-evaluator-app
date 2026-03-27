defmodule SkillsetEvaluator.Repo.Migrations.CreateAssessments do
  use Ecto.Migration

  def change do
    create table(:assessments) do
      add :name, :string, null: false
      add :description, :string
      add :created_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:assessments, [:name])

    # Add assessment_id to evaluations
    alter table(:evaluations) do
      add :assessment_id, references(:assessments, on_delete: :restrict)
    end

    create index(:evaluations, [:assessment_id])

    # Backfill: create assessments from existing distinct period values
    # and link evaluations to them
    execute(
      """
      INSERT INTO assessments (name, inserted_at, updated_at)
      SELECT DISTINCT period, datetime('now'), datetime('now')
      FROM evaluations
      WHERE period IS NOT NULL
      """,
      "SELECT 1"
    )

    execute(
      """
      UPDATE evaluations
      SET assessment_id = (
        SELECT a.id FROM assessments a WHERE a.name = evaluations.period
      )
      WHERE period IS NOT NULL
      """,
      "SELECT 1"
    )
  end
end
