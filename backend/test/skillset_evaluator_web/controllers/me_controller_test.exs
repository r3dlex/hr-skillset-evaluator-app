defmodule SkillsetEvaluatorWeb.MeControllerTest do
  use SkillsetEvaluatorWeb.ConnCase

  alias SkillsetEvaluator.Accounts

  describe "GET /api/me" do
    test "returns team data when user belongs to a team", %{conn: conn} do
      team = team_fixture(%{name: "Test Team"})
      user = user_fixture(%{name: "Teamed User", team_id: team.id})

      conn =
        conn
        |> log_in_user(user)
        |> get("/api/me")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["team"]["name"] == "Test Team"
      assert data["team"]["id"] == team.id
    end

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

    test "returns onboarding data in response", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get("/api/me")

      assert %{"data" => data} = json_response(conn, 200)
      assert %{"completed_steps" => steps, "dismissed" => dismissed} = data["onboarding"]
      assert steps == []
      assert dismissed == false
    end

    test "returns 401 when not authenticated", %{conn: conn} do
      conn = get(conn, "/api/me")
      assert json_response(conn, 401)
    end
  end

  describe "PUT /api/me/onboarding" do
    test "completes an onboarding step and returns updated state", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> put("/api/me/onboarding", %{step: "import_xlsx"})

      assert %{"completed_steps" => steps, "dismissed" => dismissed} = json_response(conn, 200)
      assert "import_xlsx" in steps
      assert dismissed == false
    end

    test "deduplicates completed steps on repeated calls", %{conn: conn} do
      user = user_fixture()
      {:ok, user} = Accounts.complete_onboarding_step(user, "import_xlsx")

      conn =
        conn
        |> log_in_user(user)
        |> put("/api/me/onboarding", %{step: "import_xlsx"})

      assert %{"completed_steps" => steps} = json_response(conn, 200)
      assert steps == ["import_xlsx"]
    end

    test "returns 401 when not authenticated", %{conn: conn} do
      conn = put(conn, "/api/me/onboarding", %{step: "import_xlsx"})
      assert json_response(conn, 401)
    end
  end

  describe "DELETE /api/me/onboarding" do
    test "dismisses onboarding and returns dismissed true", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> delete("/api/me/onboarding")

      assert %{"dismissed" => true} = json_response(conn, 200)
    end

    test "returns 401 when not authenticated", %{conn: conn} do
      conn = delete(conn, "/api/me/onboarding")
      assert json_response(conn, 401)
    end
  end
end
