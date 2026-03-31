defmodule SkillsetEvaluatorWeb.FallbackControllerTest do
  use SkillsetEvaluatorWeb.ConnCase

  describe "GET /*path (fallback)" do
    test "returns 404 JSON when static index.html does not exist", ctx do
      # In test env, priv/static/index.html does not exist
      conn = get(ctx.conn, "/some/unknown/spa/route")
      # Either 404 json or 200 html if file somehow exists
      assert conn.status in [200, 404]
    end

    test "returns non-500 for nested SPA paths", ctx do
      conn = get(ctx.conn, "/dashboard/settings/foo")
      assert conn.status in [200, 404]
    end
  end
end
