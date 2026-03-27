defmodule SkillsetEvaluator.Repo.Migrations.AddJobTitleAndApplicableRoles do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :job_title, :string
    end

    alter table(:skillsets) do
      add :applicable_roles, :string, default: "[]"
    end
  end
end
