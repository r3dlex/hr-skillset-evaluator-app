defmodule SkillsetEvaluatorWeb.SkillGroupControllerTest do
  use SkillsetEvaluatorWeb.ConnCase

  describe "POST /api/skill_groups/:id/skills" do
    test "returns 201 and creates a skill for manager", %{conn: conn} do
      manager = manager_fixture()
      skillset = skillset_fixture(%{name: "Skills Test", position: 1})
      group = skill_group_fixture(%{skillset_id: skillset.id, name: "Group A", position: 1})

      conn =
        conn
        |> log_in_user(manager)
        |> post("/api/skill_groups/#{group.id}/skills", %{
          "skill" => %{"name" => "New Skill", "priority" => "high", "position" => 1}
        })

      assert %{"data" => data} = json_response(conn, 201)
      assert data["name"] == "New Skill"
      assert data["priority"] == "high"
      assert data["skill_group_id"] == group.id
    end

    test "returns 403 when user is not a manager", %{conn: conn} do
      user = user_fixture(%{role: "user"})
      skillset = skillset_fixture(%{name: "Skills Test", position: 1})
      group = skill_group_fixture(%{skillset_id: skillset.id, name: "Group A", position: 1})

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/skill_groups/#{group.id}/skills", %{
          "skill" => %{"name" => "Forbidden", "priority" => "low"}
        })

      assert json_response(conn, 403)
    end

    test "returns 422 when skill params are invalid", %{conn: conn} do
      manager = manager_fixture()
      skillset = skillset_fixture(%{name: "Skills Test", position: 1})
      group = skill_group_fixture(%{skillset_id: skillset.id, name: "Group A", position: 1})

      conn =
        conn
        |> log_in_user(manager)
        |> post("/api/skill_groups/#{group.id}/skills", %{
          "skill" => %{"name" => ""}
        })

      assert %{"errors" => _} = json_response(conn, 422)
    end

    test "returns 401 when not authenticated", %{conn: conn} do
      conn = post(conn, "/api/skill_groups/1/skills", %{"skill" => %{"name" => "X"}})
      assert json_response(conn, 401)
    end
  end
end
