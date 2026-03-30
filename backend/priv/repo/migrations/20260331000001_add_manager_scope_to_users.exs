defmodule SkillsetEvaluator.Repo.Migrations.AddManagerScopeToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :manager_scope, :text
    end
  end
end
