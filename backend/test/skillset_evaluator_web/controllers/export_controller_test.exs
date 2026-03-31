defmodule SkillsetEvaluatorWeb.ExportControllerTest do
  use SkillsetEvaluatorWeb.ConnCase

  setup do
    manager = manager_fixture(%{name: "Export Manager"})
    user = user_fixture(%{name: "Worker"})
    skillset = skillset_fixture(%{name: "Export Skillset", position: 1})
    group = skill_group_fixture(%{skillset_id: skillset.id, name: "Group", position: 1})
    _skill = skill_fixture(%{skill_group_id: group.id, name: "Skill A", position: 1})

    %{manager: manager, user: user, skillset: skillset}
  end

  describe "GET /api/export" do
    test "returns 200 with xlsx binary for manager", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.manager)
        |> get("/api/export", %{
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2025-Q1"
        })

      assert response(conn, 200)

      assert get_resp_header(conn, "content-type") |> hd() =~
               "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

      assert get_resp_header(conn, "content-disposition") |> hd() =~ "export_2025-Q1.xlsx"
    end

    test "returns 200 with user_ids filter", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.manager)
        |> get("/api/export", %{
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2025-Q1",
          "user_ids" => to_string(ctx.user.id)
        })

      assert response(conn, 200)
    end

    test "returns 400 when missing required params", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.manager)
        |> get("/api/export")

      assert %{"error" => _} = json_response(conn, 400)
    end

    test "returns 401 when not authenticated", ctx do
      conn =
        ctx.conn
        |> get("/api/export", %{
          "skillset_id" => "1",
          "period" => "2025-Q1"
        })

      assert json_response(conn, 401)
    end

    test "returns 401 when user is not a manager", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/export", %{
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2025-Q1"
        })

      assert json_response(conn, 403) || json_response(conn, 401)
    end
  end
end
