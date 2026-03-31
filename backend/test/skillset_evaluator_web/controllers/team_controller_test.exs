defmodule SkillsetEvaluatorWeb.TeamControllerTest do
  use SkillsetEvaluatorWeb.ConnCase

  alias SkillsetEvaluator.{Repo, Teams.UserTeam}

  setup do
    manager = manager_fixture(%{name: "Team Manager"})
    user = user_fixture(%{name: "Team Member"})
    team = team_fixture(%{name: "Engineering"})

    # Add user to team
    Repo.insert!(%UserTeam{user_id: user.id, team_id: team.id})

    %{manager: manager, user: user, team: team}
  end

  describe "GET /api/teams" do
    test "returns 200 with list of teams for manager", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.manager)
        |> get("/api/teams")

      assert %{"data" => teams} = json_response(conn, 200)
      assert is_list(teams)
      assert length(teams) >= 1
      assert Enum.any?(teams, fn t -> t["name"] == "Engineering" end)
    end

    test "returns 200 with teams for regular user", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/teams")

      assert %{"data" => teams} = json_response(conn, 200)
      assert is_list(teams)
    end

    test "returns 401 when not authenticated", ctx do
      conn = get(ctx.conn, "/api/teams")
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/teams/:id" do
    test "returns 200 with team details and members", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.manager)
        |> get("/api/teams/#{ctx.team.id}")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["id"] == ctx.team.id
      assert data["name"] == "Engineering"
      assert is_list(data["members"])
      assert Enum.any?(data["members"], fn m -> m["name"] == "Team Member" end)
    end

    test "returns 404 for non-existent team", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.manager)
        |> get("/api/teams/999999")

      assert %{"error" => _} = json_response(conn, 404)
    end

    test "returns 401 when not authenticated", ctx do
      conn = get(ctx.conn, "/api/teams/#{ctx.team.id}")
      assert json_response(conn, 401)
    end
  end
end
