defmodule SkillsetEvaluatorWeb.PeriodsControllerTest do
  use SkillsetEvaluatorWeb.ConnCase

  alias SkillsetEvaluator.Repo
  alias SkillsetEvaluator.Teams.UserTeam

  setup do
    user = user_fixture(%{name: "Periods User"})
    manager = manager_fixture(%{name: "Periods Manager"})
    team = team_fixture(%{name: "Periods Team"})
    skillset = skillset_fixture()
    group = skill_group_fixture(%{skillset_id: skillset.id})
    skill = skill_fixture(%{skill_group_id: group.id})
    Repo.insert!(%UserTeam{user_id: user.id, team_id: team.id})

    # Create an evaluation so there is a period to list
    evaluation_fixture(%{
      user: user,
      skill: skill,
      period: "2025-Q1"
    })

    %{user: user, manager: manager, team: team, skillset: skillset, skill: skill}
  end

  describe "GET /api/periods" do
    test "returns 200 with periods for authenticated user", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> get("/api/periods?skillset_id=#{ctx.skillset.id}")

      assert %{"data" => periods} = json_response(conn, 200)
      assert is_list(periods)
    end

    test "returns periods filtered by user_id param", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.manager)
        |> get("/api/periods?skillset_id=#{ctx.skillset.id}&user_id=#{ctx.user.id}")

      assert %{"data" => periods} = json_response(conn, 200)
      assert is_list(periods)
    end

    test "returns periods filtered by user_ids param (comma-separated)", ctx do
      other = user_fixture()

      conn =
        ctx.conn
        |> log_in_user(ctx.manager)
        |> get("/api/periods?skillset_id=#{ctx.skillset.id}&user_ids=#{ctx.user.id},#{other.id}")

      assert %{"data" => periods} = json_response(conn, 200)
      assert is_list(periods)
    end

    test "returns periods filtered by team_id param", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.manager)
        |> get("/api/periods?skillset_id=#{ctx.skillset.id}&team_id=#{ctx.team.id}")

      assert %{"data" => periods} = json_response(conn, 200)
      assert is_list(periods)
    end

    test "returns 401 when not authenticated", ctx do
      conn = get(ctx.conn, "/api/periods?skillset_id=#{ctx.skillset.id}")
      assert json_response(conn, 401)
    end
  end
end
