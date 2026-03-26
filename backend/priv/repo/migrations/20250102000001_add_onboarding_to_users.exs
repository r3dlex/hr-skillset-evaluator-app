defmodule SkillsetEvaluator.Repo.Migrations.AddOnboardingToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :onboarding_completed_steps, :string, default: "[]"
      add :onboarding_dismissed, :boolean, default: false
    end
  end
end
