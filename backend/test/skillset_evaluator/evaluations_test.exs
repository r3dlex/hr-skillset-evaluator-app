defmodule SkillsetEvaluator.EvaluationsTest do
  use SkillsetEvaluator.DataCase

  alias SkillsetEvaluator.Evaluations

  defp setup_skillset_and_skills(_context) do
    skillset = skillset_fixture(%{name: "Test Skillset", position: 1})
    group = skill_group_fixture(%{skillset_id: skillset.id, name: "Group A", position: 1})
    skill1 = skill_fixture(%{skill_group_id: group.id, name: "Skill 1", position: 1})
    skill2 = skill_fixture(%{skill_group_id: group.id, name: "Skill 2", position: 2})
    user = user_fixture(%{name: "Evaluee"})
    manager = manager_fixture(%{name: "Manager"})

    %{
      skillset: skillset,
      group: group,
      skill1: skill1,
      skill2: skill2,
      user: user,
      manager: manager
    }
  end

  describe "upsert_manager_scores/4" do
    setup :setup_skillset_and_skills

    test "inserts new evaluations", %{manager: manager, user: user, skill1: skill1, skill2: skill2} do
      scores = [
        %{skill_id: skill1.id, score: 4},
        %{skill_id: skill2.id, score: 3}
      ]

      assert {:ok, evaluations} = Evaluations.upsert_manager_scores(manager, user.id, "2025-Q1", scores)
      assert length(evaluations) == 2

      eval1 = Enum.find(evaluations, &(&1.skill_id == skill1.id))
      assert eval1.manager_score == 4
      assert eval1.evaluated_by_id == manager.id
    end

    test "updates existing evaluations", %{manager: manager, user: user, skill1: skill1} do
      scores_initial = [%{skill_id: skill1.id, score: 2}]
      {:ok, _} = Evaluations.upsert_manager_scores(manager, user.id, "2025-Q1", scores_initial)

      scores_updated = [%{skill_id: skill1.id, score: 5, notes: "Improved"}]
      {:ok, evaluations} = Evaluations.upsert_manager_scores(manager, user.id, "2025-Q1", scores_updated)

      eval = hd(evaluations)
      assert eval.manager_score == 5
      assert eval.notes == "Improved"
    end
  end

  describe "upsert_self_scores/3" do
    setup :setup_skillset_and_skills

    test "inserts new self evaluations", %{user: user, skill1: skill1} do
      scores = [%{skill_id: skill1.id, score: 3}]

      assert {:ok, evaluations} = Evaluations.upsert_self_scores(user.id, "2025-Q1", scores)
      assert length(evaluations) == 1
      assert hd(evaluations).self_score == 3
    end

    test "updates existing self score", %{user: user, skill1: skill1} do
      scores_initial = [%{skill_id: skill1.id, score: 2}]
      {:ok, _} = Evaluations.upsert_self_scores(user.id, "2025-Q1", scores_initial)

      scores_updated = [%{skill_id: skill1.id, score: 4}]
      {:ok, evaluations} = Evaluations.upsert_self_scores(user.id, "2025-Q1", scores_updated)

      assert hd(evaluations).self_score == 4
    end
  end

  describe "list_evaluations/3" do
    setup :setup_skillset_and_skills

    test "returns evaluations for user, skillset and period", ctx do
      %{user: user, manager: manager, skill1: skill1, skill2: skill2, skillset: skillset} = ctx

      scores = [
        %{skill_id: skill1.id, score: 3},
        %{skill_id: skill2.id, score: 4}
      ]

      {:ok, _} = Evaluations.upsert_manager_scores(manager, user.id, "2025-Q1", scores)

      evaluations = Evaluations.list_evaluations(user.id, skillset.id, "2025-Q1")
      assert length(evaluations) == 2
      assert Enum.all?(evaluations, &(&1.user_id == user.id))
    end

    test "returns empty for different period", ctx do
      %{user: user, manager: manager, skill1: skill1, skillset: skillset} = ctx

      {:ok, _} = Evaluations.upsert_manager_scores(manager, user.id, "2025-Q1", [%{skill_id: skill1.id, score: 3}])

      assert Evaluations.list_evaluations(user.id, skillset.id, "2025-Q2") == []
    end
  end

  describe "get_radar_data/3" do
    setup :setup_skillset_and_skills

    test "returns labels and datasets", ctx do
      %{user: user, manager: manager, skill1: skill1, skill2: skill2, skillset: skillset} = ctx

      {:ok, _} = Evaluations.upsert_manager_scores(manager, user.id, "2025-Q1", [
        %{skill_id: skill1.id, score: 4},
        %{skill_id: skill2.id, score: 3}
      ])

      {:ok, _} = Evaluations.upsert_self_scores(user.id, "2025-Q1", [
        %{skill_id: skill1.id, score: 3},
        %{skill_id: skill2.id, score: 5}
      ])

      radar = Evaluations.get_radar_data([user.id], skillset.id, "2025-Q1")

      assert is_list(radar.labels)
      assert "Skill 1" in radar.labels
      assert "Skill 2" in radar.labels
      assert length(radar.datasets) == 1

      [dataset] = radar.datasets
      assert dataset.user_id == user.id
      assert is_list(dataset.manager_scores)
      assert is_list(dataset.self_scores)
    end
  end

  describe "get_gap_analysis/3" do
    setup :setup_skillset_and_skills

    test "returns gap between manager and self scores", ctx do
      %{user: user, manager: manager, skill1: skill1, skillset: skillset} = ctx

      {:ok, _} = Evaluations.upsert_manager_scores(manager, user.id, "2025-Q1", [
        %{skill_id: skill1.id, score: 4}
      ])

      {:ok, _} = Evaluations.upsert_self_scores(user.id, "2025-Q1", [
        %{skill_id: skill1.id, score: 2}
      ])

      gaps = Evaluations.get_gap_analysis(user.id, skillset.id, "2025-Q1")

      assert length(gaps) == 1
      [gap] = gaps
      assert gap.skill_name == "Skill 1"
      assert gap.manager_score == 4
      assert gap.self_score == 2
      assert gap.gap == 2
    end

    test "returns nil gap when a score is missing", ctx do
      %{user: user, manager: manager, skill1: skill1, skillset: skillset} = ctx

      {:ok, _} = Evaluations.upsert_manager_scores(manager, user.id, "2025-Q1", [
        %{skill_id: skill1.id, score: 3}
      ])

      gaps = Evaluations.get_gap_analysis(user.id, skillset.id, "2025-Q1")

      assert length(gaps) == 1
      [gap] = gaps
      assert gap.manager_score == 3
      assert is_nil(gap.self_score)
      assert is_nil(gap.gap)
    end
  end
end
