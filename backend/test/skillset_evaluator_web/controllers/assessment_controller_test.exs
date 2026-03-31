defmodule SkillsetEvaluatorWeb.AssessmentControllerTest do
  use SkillsetEvaluatorWeb.ConnCase

  alias SkillsetEvaluator.Assessments

  setup do
    manager = manager_fixture(%{name: "Assessment Manager"})
    user = user_fixture(%{name: "Assessment User"})

    %{manager: manager, user: user}
  end

  describe "GET /api/assessments" do
    test "returns 200 with empty list when no assessments exist", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/assessments")

      assert %{"data" => []} = json_response(conn, 200)
    end

    test "returns 200 with list of assessments", ctx do
      {:ok, _} = Assessments.create_assessment(%{name: "2025-Q1"}, ctx.manager)
      {:ok, _} = Assessments.create_assessment(%{name: "2025-Q2"}, ctx.manager)

      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/assessments")

      assert %{"data" => assessments} = json_response(conn, 200)
      assert length(assessments) == 2
    end

    test "returns assessments with skillset_id and user_ids filter", ctx do
      skillset = skillset_fixture(%{name: "Filter Skillset", position: 1})

      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/assessments", %{
          "skillset_id" => to_string(skillset.id),
          "user_ids" => to_string(ctx.user.id)
        })

      assert %{"data" => assessments} = json_response(conn, 200)
      assert is_list(assessments)
    end

    test "returns 401 when not authenticated", ctx do
      conn = get(ctx.conn, "/api/assessments")
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/assessments" do
    test "returns 201 when manager creates assessment", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.manager)
        |> post("/api/assessments", %{
          "name" => "2025-Q3",
          "description" => "Third quarter assessment"
        })

      assert %{"data" => data} = json_response(conn, 201)
      assert data["name"] == "2025-Q3"
      assert data["description"] == "Third quarter assessment"
      assert data["created_by_id"] == ctx.manager.id
    end

    test "returns 422 when name is already taken", ctx do
      {:ok, _} = Assessments.create_assessment(%{name: "Duplicate"}, ctx.manager)

      conn =
        ctx.conn
        |> log_in_user(ctx.manager)
        |> post("/api/assessments", %{"name" => "Duplicate"})

      assert json_response(conn, 422)
    end

    test "returns 400 when name is missing", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.manager)
        |> post("/api/assessments", %{})

      assert %{"error" => _} = json_response(conn, 400)
    end

    test "returns 401 when not authenticated", ctx do
      conn = post(ctx.conn, "/api/assessments", %{"name" => "Test"})
      assert json_response(conn, 401)
    end

    test "returns 401/403 when user is not a manager", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> post("/api/assessments", %{"name" => "Forbidden"})

      status = conn.status
      assert status in [401, 403]
    end
  end
end
