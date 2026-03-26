defmodule SkillsetEvaluatorWeb.EvaluationControllerTest do
  use SkillsetEvaluatorWeb.ConnCase

  alias SkillsetEvaluator.Evaluations

  setup do
    skillset = skillset_fixture(%{name: "Eval Skillset", position: 1})
    group = skill_group_fixture(%{skillset_id: skillset.id, name: "Group", position: 1})
    skill1 = skill_fixture(%{skill_group_id: group.id, name: "Skill A", position: 1})
    skill2 = skill_fixture(%{skill_group_id: group.id, name: "Skill B", position: 2})
    user = user_fixture(%{name: "Worker"})
    manager = manager_fixture(%{name: "Boss"})

    %{skillset: skillset, skill1: skill1, skill2: skill2, user: user, manager: manager}
  end

  describe "GET /api/evaluations" do
    test "returns 200 with evaluations for given params", ctx do
      %{user: user, manager: manager, skill1: skill1, skillset: skillset, conn: conn} = ctx

      {:ok, _} =
        Evaluations.upsert_manager_scores(manager, user.id, "2025-Q1", [
          %{skill_id: skill1.id, score: 3}
        ])

      conn =
        conn
        |> log_in_user(user)
        |> get("/api/evaluations", %{
          "user_id" => to_string(user.id),
          "skillset_id" => to_string(skillset.id),
          "period" => "2025-Q1"
        })

      assert %{"data" => data} = json_response(conn, 200)
      assert length(data) == 1
      assert hd(data)["manager_score"] == 3
    end

    test "returns 400 when missing required params", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/evaluations")

      assert json_response(conn, 400)
    end
  end

  describe "PUT /api/evaluations/manager" do
    test "returns 200 when manager updates scores", ctx do
      %{manager: manager, user: user, skill1: skill1, skill2: skill2, conn: conn} = ctx

      conn =
        conn
        |> log_in_user(manager)
        |> put("/api/evaluations/manager", %{
          "user_id" => to_string(user.id),
          "period" => "2025-Q1",
          "scores" => [
            %{"skill_id" => skill1.id, "score" => 4},
            %{"skill_id" => skill2.id, "score" => 5}
          ]
        })

      assert %{"data" => data} = json_response(conn, 200)
      assert length(data) == 2
    end

    test "returns 401 when not authenticated", ctx do
      conn =
        ctx.conn
        |> put("/api/evaluations/manager", %{
          "user_id" => "1",
          "period" => "2025-Q1",
          "scores" => []
        })

      assert json_response(conn, 401)
    end
  end

  describe "PUT /api/evaluations/self" do
    test "returns 200 when user updates own self scores", ctx do
      %{user: user, skill1: skill1, conn: conn} = ctx

      conn =
        conn
        |> log_in_user(user)
        |> put("/api/evaluations/self", %{
          "period" => "2025-Q1",
          "scores" => [
            %{"skill_id" => skill1.id, "score" => 3}
          ]
        })

      assert %{"data" => data} = json_response(conn, 200)
      assert length(data) == 1
      assert hd(data)["self_score"] == 3
    end
  end
end
