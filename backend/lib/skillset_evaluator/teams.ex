defmodule SkillsetEvaluator.Teams do
  @moduledoc """
  The Teams context.
  """

  import Ecto.Query
  alias SkillsetEvaluator.Repo
  alias SkillsetEvaluator.Teams.{Team, UserTeam}
  alias SkillsetEvaluator.Accounts.User

  def list_teams do
    Repo.all(Team)
  end

  def list_teams_with_member_count do
    Team
    |> join(:left, [t], ut in UserTeam, on: ut.team_id == t.id)
    |> join(:left, [t, ut], u in User, on: u.id == ut.user_id and u.active == true)
    |> group_by([t], t.id)
    |> select([t, ut, u], {t, count(u.id)})
    |> Repo.all()
    |> Enum.map(fn {team, count} -> Map.put(team, :member_count, count) end)
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

  @doc """
  List active members of a team via the user_teams join table.
  """
  def list_team_members(team_id) do
    User
    |> join(:inner, [u], ut in UserTeam, on: ut.user_id == u.id and ut.team_id == ^team_id)
    |> where([u], u.active == true)
    |> Repo.all()
  end

  @doc """
  Add a user to a team (idempotent — skips if already a member).
  """
  def add_user_to_team(user_id, team_id) do
    %UserTeam{}
    |> UserTeam.changeset(%{user_id: user_id, team_id: team_id})
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:user_id, :team_id])
  end
end
