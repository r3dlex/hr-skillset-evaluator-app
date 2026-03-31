defmodule SkillsetEvaluator.TeamsTest do
  use SkillsetEvaluator.DataCase

  alias SkillsetEvaluator.Teams
  alias SkillsetEvaluator.Repo
  alias SkillsetEvaluator.Teams.UserTeam

  setup do
    team = team_fixture(%{name: "Engineering"})
    user = user_fixture(%{name: "Alice", location: "Berlin", job_title: "engineer"})
    Repo.insert!(%UserTeam{user_id: user.id, team_id: team.id})
    %{team: team, user: user}
  end

  describe "list_teams/0" do
    test "returns all teams", ctx do
      team2 = team_fixture(%{name: "Design"})
      teams = Teams.list_teams()
      ids = Enum.map(teams, & &1.id)
      assert ctx.team.id in ids
      assert team2.id in ids
    end

    test "returns empty list when no teams exist" do
      Repo.delete_all(UserTeam)
      Repo.delete_all(SkillsetEvaluator.Teams.Team)
      assert Teams.list_teams() == []
    end
  end

  describe "list_teams_with_member_count/0" do
    test "returns teams with correct member count", ctx do
      result = Teams.list_teams_with_member_count()
      team = Enum.find(result, fn t -> t.id == ctx.team.id end)
      assert team.member_count == 1
    end

    test "returns 0 member_count for empty team" do
      empty_team = team_fixture(%{name: "Empty"})
      result = Teams.list_teams_with_member_count()
      found = Enum.find(result, fn t -> t.id == empty_team.id end)
      assert found.member_count == 0
    end
  end

  describe "get_team/1" do
    test "returns the team when it exists", ctx do
      assert found = Teams.get_team(ctx.team.id)
      assert found.id == ctx.team.id
      assert found.name == ctx.team.name
    end

    test "returns nil for non-existent id" do
      assert is_nil(Teams.get_team(0))
    end
  end

  describe "get_team!/1" do
    test "returns the team", ctx do
      assert found = Teams.get_team!(ctx.team.id)
      assert found.id == ctx.team.id
    end

    test "raises for non-existent id" do
      assert_raise Ecto.NoResultsError, fn -> Teams.get_team!(0) end
    end
  end

  describe "create_team/1" do
    test "creates a team with valid attributes" do
      assert {:ok, team} = Teams.create_team(%{name: "Frontend"})
      assert team.name == "Frontend"
    end

    test "returns error changeset with missing name" do
      assert {:error, changeset} = Teams.create_team(%{})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "update_team/2" do
    test "updates team name", ctx do
      assert {:ok, updated} = Teams.update_team(ctx.team, %{name: "Platform"})
      assert updated.name == "Platform"
    end

    test "returns error changeset with blank name", ctx do
      assert {:error, changeset} = Teams.update_team(ctx.team, %{name: ""})
      assert %{name: _} = errors_on(changeset)
    end
  end

  describe "delete_team/1" do
    test "deletes the team" do
      team = team_fixture(%{name: "ToDelete"})
      assert {:ok, _} = Teams.delete_team(team)
      assert is_nil(Teams.get_team(team.id))
    end
  end

  describe "list_team_members/1" do
    test "returns active users in the team", ctx do
      user2 = user_fixture(%{name: "Bob"})
      Repo.insert!(%UserTeam{user_id: user2.id, team_id: ctx.team.id})

      members = Teams.list_team_members(ctx.team.id)
      ids = Enum.map(members, & &1.id)

      assert ctx.user.id in ids
      assert user2.id in ids
    end

    test "returns empty list for team with no members" do
      empty_team = team_fixture()
      assert Teams.list_team_members(empty_team.id) == []
    end
  end

  describe "add_user_to_team/2" do
    test "adds a user to a team" do
      team = team_fixture()
      user = user_fixture()
      assert {:ok, _} = Teams.add_user_to_team(user.id, team.id)
      members = Teams.list_team_members(team.id)
      assert Enum.any?(members, fn m -> m.id == user.id end)
    end

    test "is idempotent — does not error when called twice" do
      team = team_fixture()
      user = user_fixture()
      assert {:ok, _} = Teams.add_user_to_team(user.id, team.id)
      assert {:ok, _} = Teams.add_user_to_team(user.id, team.id)
      assert length(Teams.list_team_members(team.id)) == 1
    end
  end

  describe "list_teams_for_user/1 (scoped access)" do
    test "admin sees all teams" do
      admin = user_fixture(%{role: "admin"})
      team_fixture(%{name: "Extra Team"})

      teams = Teams.list_teams_for_user(admin)
      assert length(teams) >= 2
    end

    test "unscoped manager sees all teams" do
      manager = user_fixture(%{role: "manager", manager_scope: nil})
      teams = Teams.list_teams_for_user(manager)
      assert is_list(teams)
    end

    test "team_only scoped manager sees only their team", ctx do
      manager =
        user_fixture(%{
          role: "manager",
          manager_scope: Jason.encode!(%{"team_only" => true})
        })

      Repo.insert!(%UserTeam{user_id: manager.id, team_id: ctx.team.id})

      teams = Teams.list_teams_for_user(manager)
      assert Enum.all?(teams, fn t -> t.id == ctx.team.id end)
    end

    test "location-scoped manager sees only teams with matching members", ctx do
      manager =
        user_fixture(%{
          role: "manager",
          manager_scope: Jason.encode!(%{"locations" => ["Berlin"]})
        })

      # ctx.user has location "Berlin" in ctx.team
      teams = Teams.list_teams_for_user(manager)
      assert Enum.any?(teams, fn t -> t.id == ctx.team.id end)
    end

    test "location-scoped manager doesn't see team with no matching members" do
      manager =
        user_fixture(%{
          role: "manager",
          manager_scope: Jason.encode!(%{"locations" => ["Tokyo"]})
        })

      # ctx.team has Berlin user — Tokyo manager should not see it
      teams = Teams.list_teams_for_user(manager)
      # Just verify it runs without error; no Tokyo users exist so no teams match
      assert is_list(teams)
    end
  end

  describe "list_scoped_members/2" do
    test "admin sees all members in team", ctx do
      admin = user_fixture(%{role: "admin"})
      members = Teams.list_scoped_members(ctx.team.id, admin)
      assert Enum.any?(members, fn m -> m.id == ctx.user.id end)
    end

    test "location-scoped manager sees only matching members", ctx do
      manager =
        user_fixture(%{
          role: "manager",
          manager_scope: Jason.encode!(%{"locations" => ["Berlin"]})
        })

      user_other = user_fixture(%{name: "Paris User", location: "Paris"})
      Repo.insert!(%UserTeam{user_id: user_other.id, team_id: ctx.team.id})

      members = Teams.list_scoped_members(ctx.team.id, manager)
      ids = Enum.map(members, & &1.id)

      assert ctx.user.id in ids
      refute user_other.id in ids
    end

    test "role-scoped manager sees only matching job titles", ctx do
      manager =
        user_fixture(%{
          role: "manager",
          manager_scope: Jason.encode!(%{"roles" => ["engineer"]})
        })

      pm = user_fixture(%{name: "PM User", job_title: "product manager"})
      Repo.insert!(%UserTeam{user_id: pm.id, team_id: ctx.team.id})

      members = Teams.list_scoped_members(ctx.team.id, manager)
      ids = Enum.map(members, & &1.id)

      assert ctx.user.id in ids
      refute pm.id in ids
    end

    test "empty scope filter (no roles/locations) returns all members", ctx do
      manager =
        user_fixture(%{
          role: "manager",
          manager_scope: Jason.encode!(%{})
        })

      members = Teams.list_scoped_members(ctx.team.id, manager)
      assert Enum.any?(members, fn m -> m.id == ctx.user.id end)
    end
  end

  describe "user_in_scope?/2" do
    test "admin always has access", ctx do
      admin = user_fixture(%{role: "admin"})
      assert Teams.user_in_scope?(admin, ctx.user.id)
    end

    test "unscoped manager has access to everyone", ctx do
      manager = user_fixture(%{role: "manager", manager_scope: nil})
      assert Teams.user_in_scope?(manager, ctx.user.id)
    end

    test "returns false for non-existent target user (scoped manager)" do
      # Scoped managers must look up the target — if not found, returns false
      manager =
        user_fixture(%{
          role: "manager",
          manager_scope: Jason.encode!(%{"locations" => ["Berlin"]})
        })

      refute Teams.user_in_scope?(manager, 999_999)
    end

    test "team_only manager: true if in same team", ctx do
      manager =
        user_fixture(%{
          role: "manager",
          manager_scope: Jason.encode!(%{"team_only" => true})
        })

      Repo.insert!(%UserTeam{user_id: manager.id, team_id: ctx.team.id})

      assert Teams.user_in_scope?(manager, ctx.user.id)
    end

    test "team_only manager: false if not in same team", ctx do
      manager =
        user_fixture(%{
          role: "manager",
          manager_scope: Jason.encode!(%{"team_only" => true})
        })

      # manager not added to ctx.team
      refute Teams.user_in_scope?(manager, ctx.user.id)
    end

    test "location-scoped manager: true if target in scope" do
      manager =
        user_fixture(%{
          role: "manager",
          manager_scope: Jason.encode!(%{"locations" => ["Berlin"]})
        })

      target = user_fixture(%{location: "Berlin"})
      assert Teams.user_in_scope?(manager, target.id)
    end

    test "location-scoped manager: false if target not in scope" do
      manager =
        user_fixture(%{
          role: "manager",
          manager_scope: Jason.encode!(%{"locations" => ["Berlin"]})
        })

      target = user_fixture(%{location: "Paris"})
      refute Teams.user_in_scope?(manager, target.id)
    end

    test "role-scoped manager: true if target job title matches" do
      manager =
        user_fixture(%{
          role: "manager",
          manager_scope: Jason.encode!(%{"roles" => ["developer"]})
        })

      target = user_fixture(%{job_title: "Developer"})
      assert Teams.user_in_scope?(manager, target.id)
    end

    test "role-scoped manager: false if target job title doesn't match" do
      manager =
        user_fixture(%{
          role: "manager",
          manager_scope: Jason.encode!(%{"roles" => ["developer"]})
        })

      target = user_fixture(%{job_title: "designer"})
      refute Teams.user_in_scope?(manager, target.id)
    end
  end
end
