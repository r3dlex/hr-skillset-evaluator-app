defmodule SkillsetEvaluator.Teams do
  @moduledoc """
  The Teams context.
  """

  import Ecto.Query
  alias SkillsetEvaluator.Repo
  alias SkillsetEvaluator.Teams.Team
  alias SkillsetEvaluator.Accounts.User

  def list_teams do
    Repo.all(Team)
  end

  def get_team(id), do: Repo.get(Team, id)

  def get_team!(id), do: Repo.get!(Team, id)

  def create_team(attrs) do
    %Team{}
    |> Team.changeset(attrs)
    |> Repo.insert()
  end

  def update_team(%Team{} = team, attrs) do
    team
    |> Team.changeset(attrs)
    |> Repo.update()
  end

  def delete_team(%Team{} = team) do
    Repo.delete(team)
  end

  def list_team_members(team_id) do
    User
    |> where([u], u.team_id == ^team_id and u.active == true)
    |> Repo.all()
  end
end
