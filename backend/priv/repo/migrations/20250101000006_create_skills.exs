defmodule SkillsetEvaluator.Repo.Migrations.CreateSkills do
  use Ecto.Migration

  def change do
    create table(:skills) do
      add :name, :string, null: false
      add :priority, :string
      add :position, :integer
      add :skill_group_id, references(:skill_groups, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:skills, [:skill_group_id])
  end
end
