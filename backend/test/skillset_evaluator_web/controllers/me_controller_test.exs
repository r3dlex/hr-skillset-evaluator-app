defmodule SkillsetEvaluatorWeb.MeControllerTest do
  use SkillsetEvaluatorWeb.ConnCase

  describe "GET /api/me" do
    test "returns 200 and current user data when authenticated", %{conn: conn} do
      user = user_fixture(%{name: "Me User", role: "user"})

      conn =
        conn
        |> log_in_user(user)
        |> get("/api/me")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["id"] == user.id
      assert data["email"] == user.email
      assert data["name"] == "Me User"
      assert data["role"] == "user"
    end

    test "returns 401 when not authenticated", %{conn: conn} do
      conn = get(conn, "/api/me")
      assert json_response(conn, 401)
    end
  end
end
