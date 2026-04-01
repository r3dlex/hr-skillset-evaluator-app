defmodule SkillsetEvaluator.AssessmentsTest do
  use SkillsetEvaluator.DataCase

  alias SkillsetEvaluator.Assessments

  describe "list_assessments/0" do
    test "returns empty list when no assessments" do
      assert Assessments.list_assessments() == []
    end

    test "returns all assessments ordered by insertion time" do
      {:ok, a1} = Assessments.create_assessment(%{name: "2025-Q1"}, user_fixture())
      {:ok, a2} = Assessments.create_assessment(%{name: "2025-Q2"}, user_fixture())

      result = Assessments.list_assessments()
      assert length(result) >= 2
      ids = Enum.map(result, & &1.id)
      assert a1.id in ids
      assert a2.id in ids
    end
  end

  describe "list_assessments_with_data/2" do
    test "returns empty list when user_ids is empty" do
      skillset = skillset_fixture()
      assert Assessments.list_assessments_with_data([], skillset.id) == []
    end

    test "returns assessments that have evaluation data for given users" do
      user = user_fixture()
      manager = manager_fixture()
      skillset = skillset_fixture(%{name: "Test Skillset", position: 1})
      group = skill_group_fixture(%{skillset_id: skillset.id, name: "Test Group"})
      skill = skill_fixture(%{skill_group_id: group.id, name: "Test Skill"})

      assessment_fixture = fn name ->
        {:ok, a} = Assessments.create_assessment(%{name: name}, manager)
        a
      end

      assessment = assessment_fixture.("2025-Q1")

      evaluation_fixture(%{
        user: user,
        skill: skill,
        period: "2025-Q1",
        assessment_id: assessment.id
      })

      result = Assessments.list_assessments_with_data([user.id], skillset.id)
      assert Enum.any?(result, fn a -> a.id == assessment.id end)
    end

    test "returns empty list when no evaluations exist for given users" do
      user = user_fixture()
      skillset = skillset_fixture()
      assert Assessments.list_assessments_with_data([user.id], skillset.id) == []
    end
  end

  describe "get_assessment/1" do
    test "returns assessment by id" do
      {:ok, assessment} = Assessments.create_assessment(%{name: "2025-Q1"}, user_fixture())
      assert Assessments.get_assessment(assessment.id) == assessment
    end

    test "returns nil for non-existent id" do
      assert Assessments.get_assessment(999_999) == nil
    end
  end

  describe "get_assessment_by_name/1" do
    test "returns assessment by name" do
      {:ok, assessment} = Assessments.create_assessment(%{name: "2026-Q1"}, user_fixture())
      result = Assessments.get_assessment_by_name("2026-Q1")
      assert result.id == assessment.id
    end

    test "returns nil when not found" do
      assert Assessments.get_assessment_by_name("9999-Q9") == nil
    end
  end

  describe "create_assessment/2" do
    test "creates a valid assessment with a user" do
      user = user_fixture()
      assert {:ok, assessment} = Assessments.create_assessment(%{name: "2025-Q1"}, user)
      assert assessment.name == "2025-Q1"
      assert assessment.created_by_id == user.id
    end

    test "returns changeset error for blank name" do
      user = user_fixture()
      assert {:error, changeset} = Assessments.create_assessment(%{name: ""}, user)
      assert changeset.errors[:name]
    end
  end

  describe "find_or_create_assessment/2" do
    test "creates assessment when it does not exist" do
      user = user_fixture()
      assert {:ok, assessment} = Assessments.find_or_create_assessment("2025-Q3", user)
      assert assessment.name == "2025-Q3"
    end

    test "returns existing assessment when it already exists" do
      user = user_fixture()
      {:ok, first} = Assessments.find_or_create_assessment("2025-Q4", user)
      {:ok, second} = Assessments.find_or_create_assessment("2025-Q4", user)
      assert first.id == second.id
    end

    test "creates assessment without created_by when nil" do
      assert {:ok, assessment} = Assessments.find_or_create_assessment("2026-Q2")
      assert assessment.name == "2026-Q2"
      assert is_nil(assessment.created_by_id)
    end
  end
end
