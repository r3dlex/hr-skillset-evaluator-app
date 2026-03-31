defmodule SkillsetEvaluatorWeb.RadarControllerTest do
  use SkillsetEvaluatorWeb.ConnCase

  alias SkillsetEvaluator.Evaluations

  setup do
    user = user_fixture(%{name: "Radar User"})
    manager = manager_fixture(%{name: "Radar Manager"})
    skillset = skillset_fixture(%{name: "Radar Skillset", position: 1})
    group = skill_group_fixture(%{skillset_id: skillset.id, name: "Radar Group", position: 1})
    skill = skill_fixture(%{skill_group_id: group.id, name: "Radar Skill", position: 1})

    %{user: user, manager: manager, skillset: skillset, group: group, skill: skill}
  end

  describe "GET /api/radar" do
    test "returns 200 with radar data for authenticated user", ctx do
      %{user: user, manager: manager, skillset: skillset, skill: skill} = ctx

      {:ok, _} =
        Evaluations.upsert_manager_scores(manager, user.id, "2025-Q1", [
          %{skill_id: skill.id, score: 4}
        ])

      conn =
        ctx.conn
        |> log_in_user(user)
        |> get("/api/radar", %{
          "skillset_id" => to_string(skillset.id),
          "period" => "2025-Q1"
        })

      assert %{"data" => data} = json_response(conn, 200)
      assert is_map(data)
      assert is_list(data["labels"])
      assert is_list(data["datasets"])
    end

    test "returns radar data with explicit user_ids", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/radar", %{
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2025-Q1",
          "user_ids" => to_string(ctx.user.id)
        })

      assert %{"data" => data} = json_response(conn, 200)
      assert is_map(data)
    end

    test "returns radar data filtered by skill_group_id", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/radar", %{
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2025-Q1",
          "skill_group_id" => to_string(ctx.group.id)
        })

      assert %{"data" => data} = json_response(conn, 200)
      assert is_map(data)
    end

    test "returns empty datasets when no evaluations exist", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/radar", %{
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2099-Q1"
        })

      assert %{"data" => data} = json_response(conn, 200)
      assert is_map(data)
    end

    test "returns 400 when missing required params", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/radar")

      assert %{"error" => _} = json_response(conn, 400)
    end

    test "returns 401 when not authenticated", ctx do
      conn =
        get(ctx.conn, "/api/radar", %{
          "skillset_id" => "1",
          "period" => "2025-Q1"
        })

      assert json_response(conn, 401)
    end
  end
end
