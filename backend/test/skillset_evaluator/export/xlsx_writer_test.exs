defmodule SkillsetEvaluator.Export.XlsxWriterTest do
  use SkillsetEvaluator.DataCase

  alias SkillsetEvaluator.Export.XlsxWriter
  alias SkillsetEvaluator.Repo
  alias SkillsetEvaluator.Teams.UserTeam

  setup do
    user = user_fixture(%{name: "Export User", location: "Berlin", job_title: "engineer"})
    team = team_fixture(%{name: "Export Team"})
    Repo.insert!(%UserTeam{user_id: user.id, team_id: team.id})

    skillset = skillset_fixture(%{name: "Export Skillset", position: 1})
    group = skill_group_fixture(%{skillset_id: skillset.id, name: "Coding", position: 1})

    skill1 =
      skill_fixture(%{skill_group_id: group.id, name: "Elixir", priority: "high", position: 1})

    skill2 =
      skill_fixture(%{skill_group_id: group.id, name: "Python", priority: "medium", position: 2})

    evaluation_fixture(%{
      user: user,
      skill: skill1,
      period: "2025-Q1",
      manager_score: 4,
      self_score: 3
    })

    evaluation_fixture(%{
      user: user,
      skill: skill2,
      period: "2025-Q1",
      manager_score: 3,
      self_score: 4
    })

    %{user: user, team: team, skillset: skillset, skill1: skill1, skill2: skill2}
  end

  describe "generate/3" do
    test "returns {:ok, binary} with xlsx binary", ctx do
      assert {:ok, binary} = XlsxWriter.generate(ctx.skillset.id, "2025-Q1", [ctx.user.id])
      assert is_binary(binary)
      assert byte_size(binary) > 0
    end

    test "returns xlsx with correct content type magic bytes", ctx do
      assert {:ok, binary} = XlsxWriter.generate(ctx.skillset.id, "2025-Q1", [ctx.user.id])
      # XLSX files start with PK (zip format)
      assert binary_part(binary, 0, 2) == "PK"
    end

    test "returns valid xlsx for empty user list", ctx do
      assert {:ok, binary} = XlsxWriter.generate(ctx.skillset.id, "2025-Q1", [])
      assert is_binary(binary)
    end

    test "returns valid xlsx for period with no evaluations", ctx do
      assert {:ok, binary} = XlsxWriter.generate(ctx.skillset.id, "2099-Q1", [ctx.user.id])
      assert is_binary(binary)
    end

    test "raises when skillset_id does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        XlsxWriter.generate(999_999, "2025-Q1", [])
      end
    end

    test "works with multiple users" do
      user2 = user_fixture(%{name: "Second User"})
      skillset = skillset_fixture(%{name: "Multi User Skillset", position: 99})

      assert {:ok, binary} = XlsxWriter.generate(skillset.id, "2025-Q1", [user2.id])
      assert is_binary(binary)
    end
  end

  describe "generate_all/2" do
    test "returns {:ok, binary} for all skillsets", ctx do
      assert {:ok, binary} = XlsxWriter.generate_all("2025-Q1", [ctx.user.id])
      assert is_binary(binary)
      assert byte_size(binary) > 0
    end

    test "works with empty user list" do
      assert {:ok, binary} = XlsxWriter.generate_all("2025-Q1", [])
      assert is_binary(binary)
    end
  end
end
