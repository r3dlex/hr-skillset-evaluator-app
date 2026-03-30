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

  # ---------------------------------------------------------------------------
  # Scoped access — filters teams and members based on manager_scope
  # ---------------------------------------------------------------------------

  @doc """
  List teams visible to the given user, respecting their manager_scope.
  Admins and unscoped managers see all teams. Scoped managers see filtered results.
  """
  def list_teams_for_user(%User{} = user) do
    if User.has_full_access?(user) do
      list_teams_with_member_count()
    else
      scope = User.parsed_scope(user) || %{}

      cond do
        scope["team_only"] == true ->
          # Only the user's own team(s)
          user_team_ids = user_team_ids(user.id)

          Team
          |> where([t], t.id in ^user_team_ids)
          |> join(:left, [t], ut in UserTeam, on: ut.team_id == t.id)
          |> join(:left, [t, ut], u in User, on: u.id == ut.user_id and u.active == true)
          |> group_by([t], t.id)
          |> select([t, ut, u], {t, count(u.id)})
          |> Repo.all()
          |> Enum.map(fn {team, count} -> Map.put(team, :member_count, count) end)

        true ->
          # Scoped by roles/locations — return teams that have matching members
          list_teams_with_member_count()
          |> filter_teams_by_scope(scope)
      end
    end
  end

  @doc """
  List members of a team visible to the given user, respecting their manager_scope.
  """
  def list_scoped_members(team_id, %User{} = user) do
    members = list_team_members(team_id)

    if User.has_full_access?(user) do
      members
    else
      scope = User.parsed_scope(user) || %{}
      filter_members_by_scope(members, scope)
    end
  end

  @doc """
  Returns true if the given target user is within the manager's scope.
  Used for authorization checks on write operations.
  """
  def user_in_scope?(%User{} = manager, target_user_id) when is_integer(target_user_id) do
    if User.has_full_access?(manager) do
      true
    else
      scope = User.parsed_scope(manager) || %{}
      target = Repo.get(User, target_user_id)

      if target == nil do
        false
      else
        # Check team_only
        if scope["team_only"] == true do
          manager_teams = user_team_ids(manager.id)
          target_teams = user_team_ids(target.id)
          # Must share at least one team
          Enum.any?(manager_teams, fn t -> t in target_teams end) and
            member_matches_scope?(target, scope)
        else
          member_matches_scope?(target, scope)
        end
      end
    end
  end

  # Private helpers

  defp user_team_ids(user_id) do
    UserTeam
    |> where([ut], ut.user_id == ^user_id)
    |> select([ut], ut.team_id)
    |> Repo.all()
  end

  defp filter_teams_by_scope(teams, scope) do
    locations = scope["locations"] || []

    if locations == [] do
      teams
    else
      # Only keep teams that have members in the matching locations
      Enum.filter(teams, fn team ->
        members = list_team_members(team.id)
        Enum.any?(members, fn m -> m.location in locations end)
      end)
    end
  end

  defp filter_members_by_scope(members, scope) do
    members
    |> filter_by_roles(scope["roles"] || [])
    |> filter_by_locations(scope["locations"] || [])
  end

  defp filter_by_roles(members, []), do: members

  defp filter_by_roles(members, roles) do
    downcased = Enum.map(roles, &String.downcase/1)
    Enum.filter(members, fn m -> m.job_title && String.downcase(m.job_title) in downcased end)
  end

  defp filter_by_locations(members, []), do: members

  defp filter_by_locations(members, locations) do
    downcased = Enum.map(locations, &String.downcase/1)
    Enum.filter(members, fn m -> m.location && String.downcase(m.location) in downcased end)
  end

  defp member_matches_scope?(member, scope) do
    roles = scope["roles"] || []
    locations = scope["locations"] || []

    role_ok =
      roles == [] or
        (member.job_title != nil and
           String.downcase(member.job_title) in Enum.map(roles, &String.downcase/1))

    location_ok =
      locations == [] or
        (member.location != nil and
           String.downcase(member.location) in Enum.map(locations, &String.downcase/1))

    role_ok and location_ok
  end
end
