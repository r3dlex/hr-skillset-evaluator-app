defmodule SkillsetEvaluatorWeb.SkillsetControllerTest do
  use SkillsetEvaluatorWeb.ConnCase

  describe "GET /api/skillsets" do
    test "returns 200 and a list of skillsets when authenticated", %{conn: conn} do
      user = user_fixture()
      s1 = skillset_fixture(%{name: "Frontend", position: 1})
      s2 = skillset_fixture(%{name: "Backend", position: 2})

      conn =
        conn
        |> log_in_user(user)
        |> get("/api/skillsets")

      assert %{"data" => data} = json_response(conn, 200)
      ids = Enum.map(data, & &1["id"])
      assert s1.id in ids
      assert s2.id in ids
    end

    test "returns 401 when not authenticated", %{conn: conn} do
      conn = get(conn, "/api/skillsets")
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/skillsets/:id" do
    test "returns 200 with skillset and skill groups", %{conn: conn} do
      user = user_fixture()
      skillset = skillset_fixture(%{name: "DevOps"})
      group = skill_group_fixture(%{skillset_id: skillset.id, name: "CI/CD", position: 1})
      skill = skill_fixture(%{skill_group_id: group.id, name: "Jenkins", position: 1})

      conn =
        conn
        |> log_in_user(user)
        |> get("/api/skillsets/#{skillset.id}")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["id"] == skillset.id
      assert data["name"] == "DevOps"
      assert [sg] = data["skill_groups"]
      assert sg["name"] == "CI/CD"
      assert [sk] = sg["skills"]
      assert sk["id"] == skill.id
      assert sk["name"] == "Jenkins"
    end

    test "returns 404 for non-existent skillset", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get("/api/skillsets/0")

      assert json_response(conn, 404)
    end
  end

  describe "POST /api/skillsets" do
    test "returns 201 when created by a manager", %{conn: conn} do
      manager = manager_fixture()

      conn =
        conn
        |> log_in_user(manager)
        |> post("/api/skillsets", %{
          "skillset" => %{"name" => "New Skillset", "description" => "desc", "position" => 1}
        })

      assert %{"data" => data} = json_response(conn, 201)
      assert data["name"] == "New Skillset"
    end

    test "returns 401 when not authenticated", %{conn: conn} do
      conn = post(conn, "/api/skillsets", %{"skillset" => %{"name" => "X", "position" => 1}})
      assert json_response(conn, 401)
    end

    test "returns 403 when user is not a manager", %{conn: conn} do
      user = user_fixture(%{role: "user"})

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/skillsets", %{
          "skillset" => %{"name" => "Forbidden", "position" => 1}
        })

      assert json_response(conn, 403)
    end

    test "returns 422 when skillset params are invalid (missing name)", %{conn: conn} do
      manager = manager_fixture()

      conn =
        conn
        |> log_in_user(manager)
        |> post("/api/skillsets", %{
          "skillset" => %{"name" => "", "position" => 1}
        })

      assert %{"errors" => errors} = json_response(conn, 422)
      assert is_map(errors)
    end
  end

  describe "PUT /api/skillsets/:id" do
    test "returns 200 and updated skillset for manager", %{conn: conn} do
      manager = manager_fixture()
      skillset = skillset_fixture(%{name: "Original", position: 1})

      conn =
        conn
        |> log_in_user(manager)
        |> put("/api/skillsets/#{skillset.id}", %{
          "skillset" => %{"name" => "Updated Name"}
        })

      assert %{"data" => data} = json_response(conn, 200)
      assert data["name"] == "Updated Name"
    end

    test "returns 404 for non-existent skillset", %{conn: conn} do
      manager = manager_fixture()

      conn =
        conn
        |> log_in_user(manager)
        |> put("/api/skillsets/0", %{"skillset" => %{"name" => "X"}})

      assert json_response(conn, 404)
    end

    test "returns 403 when user is not a manager", %{conn: conn} do
      user = user_fixture(%{role: "user"})
      skillset = skillset_fixture(%{name: "Original", position: 1})

      conn =
        conn
        |> log_in_user(user)
        |> put("/api/skillsets/#{skillset.id}", %{"skillset" => %{"name" => "Hacked"}})

      assert json_response(conn, 403)
    end
  end

  describe "POST /api/skillsets/:id/skill_groups" do
    test "returns 201 and creates a skill group for manager", %{conn: conn} do
      manager = manager_fixture()
      skillset = skillset_fixture(%{name: "Target", position: 1})

      conn =
        conn
        |> log_in_user(manager)
        |> post("/api/skillsets/#{skillset.id}/skill_groups", %{
          "skill_group" => %{"name" => "New Group", "position" => 1}
        })

      assert %{"data" => data} = json_response(conn, 201)
      assert data["name"] == "New Group"
      assert data["skillset_id"] == skillset.id
    end

    test "returns 403 when user is not a manager", %{conn: conn} do
      user = user_fixture(%{role: "user"})
      skillset = skillset_fixture(%{name: "Target", position: 1})

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/skillsets/#{skillset.id}/skill_groups", %{
          "skill_group" => %{"name" => "Group"}
        })

      assert json_response(conn, 403)
    end

    test "returns 422 when skill_group params are invalid", %{conn: conn} do
      manager = manager_fixture()
      skillset = skillset_fixture(%{name: "Target", position: 1})

      conn =
        conn
        |> log_in_user(manager)
        |> post("/api/skillsets/#{skillset.id}/skill_groups", %{
          "skill_group" => %{"name" => ""}
        })

      assert %{"errors" => _} = json_response(conn, 422)
    end
  end
end
