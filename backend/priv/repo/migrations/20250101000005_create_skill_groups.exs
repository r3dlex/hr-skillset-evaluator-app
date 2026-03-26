defmodule SkillsetEvaluator.Repo.Migrations.CreateSkillGroups do
  use Ecto.Migration

  def change do
    create table(:skill_groups) do
      add :name, :string, null: false
      add :position, :integer
      add :skillset_id, references(:skillsets, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:skill_groups, [:skillset_id])
  end
end
