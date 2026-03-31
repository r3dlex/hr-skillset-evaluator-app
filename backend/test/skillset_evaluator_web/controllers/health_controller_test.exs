defmodule SkillsetEvaluatorWeb.HealthControllerTest do
  use SkillsetEvaluatorWeb.ConnCase

  describe "GET /api/health" do
    test "returns 200 with status ok", ctx do
      conn = get(ctx.conn, "/api/health")
      assert %{"status" => "ok"} = json_response(conn, 200)
    end

    test "does not require authentication", ctx do
      conn = get(ctx.conn, "/api/health")
      assert conn.status == 200
    end
  end
end
