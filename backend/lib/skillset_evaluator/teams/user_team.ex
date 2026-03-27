defmodule SkillsetEvaluator.Teams.UserTeam do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_teams" do
    belongs_to :user, SkillsetEvaluator.Accounts.User
    belongs_to :team, SkillsetEvaluator.Teams.Team

    timestamps(type: :utc_datetime)
  end

  def changeset(user_team, attrs) do
    user_team
    |> cast(attrs, [:user_id, :team_id])
    |> validate_required([:user_id, :team_id])
    |> unique_constraint([:user_id, :team_id])
  end
end
