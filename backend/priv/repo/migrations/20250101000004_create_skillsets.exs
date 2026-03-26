defmodule SkillsetEvaluator.Repo.Migrations.CreateSkillsets do
  use Ecto.Migration

  def change do
    create table(:skillsets) do
      add :name, :string, null: false
      add :description, :string
      add :position, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
