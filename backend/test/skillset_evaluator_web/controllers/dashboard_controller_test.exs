defmodule SkillsetEvaluatorWeb.DashboardControllerTest do
  use SkillsetEvaluatorWeb.ConnCase

  alias SkillsetEvaluator.{Repo, Teams.UserTeam, Evaluations}

  setup do
    user = user_fixture(%{name: "Worker"})
    manager = manager_fixture(%{name: "Boss"})
    team = team_fixture(%{name: "Alpha"})
    skillset = skillset_fixture(%{name: "Dashboard Skillset", position: 1})
    group = skill_group_fixture(%{skillset_id: skillset.id, name: "Group", position: 1})
    skill = skill_fixture(%{skill_group_id: group.id, name: "Skill A", position: 1})

    # Add user to team
    Repo.insert!(%UserTeam{user_id: user.id, team_id: team.id})

    %{user: user, manager: manager, team: team, skillset: skillset, skill: skill}
  end

  describe "GET /api/dashboard/stats" do
    test "returns 200 with stats for authenticated user", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/dashboard/stats")

      assert %{"data" => data} = json_response(conn, 200)
      assert is_integer(data["total_skills"])
      assert is_number(data["average_score"])
      assert is_integer(data["skills_rated"])
      assert is_integer(data["completion_percentage"])
      assert is_integer(data["team_size"])
    end

    test "returns stats filtered by team_id", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/dashboard/stats", %{"team_id" => to_string(ctx.team.id)})

      assert %{"data" => data} = json_response(conn, 200)
      assert data["team_size"] == 1
    end

    test "returns stats filtered by period", ctx do
      %{manager: manager, user: user, skill: skill} = ctx

      {:ok, _} =
        Evaluations.upsert_manager_scores(manager, user.id, "2025-Q1", [
          %{skill_id: skill.id, score: 4}
        ])

      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/dashboard/stats", %{"period" => "2025-Q1"})

      assert %{"data" => data} = json_response(conn, 200)
      assert data["skills_rated"] >= 1
      assert data["average_score"] > 0
    end

    test "returns zero stats when no evaluations exist", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/dashboard/stats")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["skills_rated"] == 0
      assert data["average_score"] == 0
    end

    test "returns 401 when not authenticated", ctx do
      conn = get(ctx.conn, "/api/dashboard/stats")
      assert json_response(conn, 401)
    end

    test "stats filtered by period with no evaluations gives 0 average", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/dashboard/stats", %{"period" => "9999-Q9"})

      assert %{"data" => data} = json_response(conn, 200)
      assert data["skills_rated"] == 0
      assert data["average_score"] == 0
    end
  end
end
