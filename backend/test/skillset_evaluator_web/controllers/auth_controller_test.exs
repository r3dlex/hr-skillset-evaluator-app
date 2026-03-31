defmodule SkillsetEvaluatorWeb.AuthControllerTest do
  use SkillsetEvaluatorWeb.ConnCase

  describe "POST /api/auth/login" do
    test "returns 200 and user data with valid credentials", %{conn: conn} do
      user = user_fixture(%{name: "LoginUser"})

      conn =
        conn
        |> post("/api/auth/login", %{
          "email" => user.email,
          "password" => valid_user_password()
        })

      assert %{"data" => data} = json_response(conn, 200)
      assert data["id"] == user.id
      assert data["email"] == user.email
      assert data["name"] == "LoginUser"
    end

    test "returns 401 with invalid password", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> post("/api/auth/login", %{
          "email" => user.email,
          "password" => "wrongpassword123"
        })

      assert %{"error" => _} = json_response(conn, 401)
    end

    test "returns 401 with non-existent email", %{conn: conn} do
      conn =
        conn
        |> post("/api/auth/login", %{
          "email" => "nobody@example.com",
          "password" => "somepassword1"
        })

      assert %{"error" => _} = json_response(conn, 401)
    end
  end

  describe "DELETE /api/auth/logout" do
    test "returns 200 and clears session when logged in", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      conn = delete(conn, "/api/auth/logout")

      assert %{"message" => "Logged out successfully."} = json_response(conn, 200)
    end

    test "returns 200 even when not logged in (no token in session)", %{conn: conn} do
      conn = delete(conn, "/api/auth/logout")
      assert %{"message" => "Logged out successfully."} = json_response(conn, 200)
    end
  end
end
