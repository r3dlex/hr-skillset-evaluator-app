defmodule SkillsetEvaluatorWeb.GapAnalysisControllerTest do
  use SkillsetEvaluatorWeb.ConnCase

  alias SkillsetEvaluator.Evaluations

  setup do
    user = user_fixture(%{name: "Gap User"})
    manager = manager_fixture(%{name: "Gap Manager"})
    skillset = skillset_fixture(%{name: "Gap Skillset", position: 1})
    group = skill_group_fixture(%{skillset_id: skillset.id, name: "Gap Group", position: 1})
    skill = skill_fixture(%{skill_group_id: group.id, name: "Gap Skill", position: 1})

    %{user: user, manager: manager, skillset: skillset, group: group, skill: skill}
  end

  describe "GET /api/gap-analysis" do
    test "returns 200 with gap analysis data", ctx do
      %{user: user, manager: manager, skillset: skillset, skill: skill} = ctx

      {:ok, _} =
        Evaluations.upsert_manager_scores(manager, user.id, "2025-Q1", [
          %{skill_id: skill.id, score: 3}
        ])

      conn =
        ctx.conn
        |> log_in_user(user)
        |> get("/api/gap-analysis", %{
          "skillset_id" => to_string(skillset.id),
          "period" => "2025-Q1"
        })

      assert %{"data" => data} = json_response(conn, 200)
      assert is_list(data)
      assert length(data) >= 1

      item = hd(data)
      assert Map.has_key?(item, "name")
      assert Map.has_key?(item, "skill_id")
      assert Map.has_key?(item, "manager_score")
      assert Map.has_key?(item, "gap")
    end

    test "returns gap analysis for explicit user_id", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.manager)
        |> get("/api/gap-analysis", %{
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2025-Q1",
          "user_id" => to_string(ctx.user.id)
        })

      assert %{"data" => data} = json_response(conn, 200)
      assert is_list(data)
    end

    test "returns gap analysis filtered by skill_group_id", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/gap-analysis", %{
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2025-Q1",
          "skill_group_id" => to_string(ctx.group.id)
        })

      assert %{"data" => data} = json_response(conn, 200)
      assert is_list(data)
    end

    test "returns empty list when no evaluations exist", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/gap-analysis", %{
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2099-Q1"
        })

      assert %{"data" => []} = json_response(conn, 200)
    end

    test "returns 400 when missing required params", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/gap-analysis")

      assert %{"error" => _} = json_response(conn, 400)
    end

    test "returns 401 when not authenticated", ctx do
      conn =
        get(ctx.conn, "/api/gap-analysis", %{
          "skillset_id" => "1",
          "period" => "2025-Q1"
        })

      assert json_response(conn, 401)
    end
  end
end
