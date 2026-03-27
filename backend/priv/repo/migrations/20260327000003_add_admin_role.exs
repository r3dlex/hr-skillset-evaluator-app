defmodule SkillsetEvaluator.Repo.Migrations.AddAdminRole do
  use Ecto.Migration

  def change do
    # No schema change needed — role is already a string field on users.
    # The "admin" value is already allowed in User.changeset validation.
    # This migration exists as a placeholder; the seeds update handles
    # setting the first user as admin.
    :ok
  end
end
