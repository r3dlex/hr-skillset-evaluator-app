defmodule SkillsetEvaluator.TeamsTest do
  use SkillsetEvaluator.DataCase

  alias SkillsetEvaluator.Teams

  describe "list_teams/0" do
    test "returns all teams" do
      team1 = team_fixture(%{name: "Alpha"})
      team2 = team_fixture(%{name: "Beta"})

      teams = Teams.list_teams()
      ids = Enum.map(teams, & &1.id)

      assert team1.id in ids
      assert team2.id in ids
    end

    test "returns empty list when no teams exist" do
      assert Teams.list_teams() == []
    end
  end

  describe "create_team/1" do
    test "creates a team with valid attributes" do
      assert {:ok, team} = Teams.create_team(%{name: "Engineering"})
      assert team.name == "Engineering"
    end

    test "returns error changeset with missing name" do
      assert {:error, changeset} = Teams.create_team(%{})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "get_team/1" do
    test "returns the team when it exists" do
      team = team_fixture()
      assert found = Teams.get_team(team.id)
      assert found.id == team.id
      assert found.name == team.name
    end

    test "returns nil for non-existent id" do
      assert is_nil(Teams.get_team(0))
    end
  end

  describe "list_team_members/1" do
    test "returns active users in the team" do
      team = team_fixture()
      user1 = user_fixture(%{team_id: team.id, name: "Member1"})
      user2 = user_fixture(%{team_id: team.id, name: "Member2"})
      _outsider = user_fixture(%{name: "Outsider"})

      members = Teams.list_team_members(team.id)
      ids = Enum.map(members, & &1.id)

      assert user1.id in ids
      assert user2.id in ids
      assert length(ids) == 2
    end

    test "returns empty list for team with no members" do
      team = team_fixture()
      assert Teams.list_team_members(team.id) == []
    end
  end
end
