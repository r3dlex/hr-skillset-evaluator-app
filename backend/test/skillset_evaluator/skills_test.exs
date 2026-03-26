defmodule SkillsetEvaluator.SkillsTest do
  use SkillsetEvaluator.DataCase

  alias SkillsetEvaluator.Skills

  describe "list_skillsets/0" do
    test "returns all skillsets ordered by position" do
      s1 = skillset_fixture(%{name: "First", position: 1})
      s2 = skillset_fixture(%{name: "Second", position: 2})

      skillsets = Skills.list_skillsets()
      ids = Enum.map(skillsets, & &1.id)

      assert ids == [s1.id, s2.id]
    end

    test "returns empty list when no skillsets exist" do
      assert Skills.list_skillsets() == []
    end
  end

  describe "get_skillset/1" do
    test "returns the skillset with preloaded groups and skills" do
      skillset = skillset_fixture()
      group = skill_group_fixture(%{skillset_id: skillset.id, name: "Group A", position: 1})
      skill = skill_fixture(%{skill_group_id: group.id, name: "Skill A", position: 1})

      result = Skills.get_skillset(skillset.id)

      assert result.id == skillset.id
      assert length(result.skill_groups) == 1

      [loaded_group] = result.skill_groups
      assert loaded_group.id == group.id
      assert length(loaded_group.skills) == 1
      assert hd(loaded_group.skills).id == skill.id
    end

    test "returns nil for non-existent id" do
      assert is_nil(Skills.get_skillset(0))
    end
  end

  describe "create_skillset/1" do
    test "creates a skillset with valid attributes" do
      attrs = %{name: "Backend Skills", description: "Server stuff", position: 1}
      assert {:ok, skillset} = Skills.create_skillset(attrs)
      assert skillset.name == "Backend Skills"
      assert skillset.description == "Server stuff"
    end

    test "returns error with missing name" do
      assert {:error, changeset} = Skills.create_skillset(%{position: 1})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "create_skill_group/1" do
    test "creates a skill group linked to a skillset" do
      skillset = skillset_fixture()
      attrs = %{name: "Communication", position: 1, skillset_id: skillset.id}

      assert {:ok, group} = Skills.create_skill_group(attrs)
      assert group.name == "Communication"
      assert group.skillset_id == skillset.id
    end
  end

  describe "create_skill/1" do
    test "creates a skill linked to a group" do
      group = skill_group_fixture()
      attrs = %{name: "Active Listening", priority: "high", position: 1, skill_group_id: group.id}

      assert {:ok, skill} = Skills.create_skill(attrs)
      assert skill.name == "Active Listening"
      assert skill.priority == "high"
      assert skill.skill_group_id == group.id
    end
  end
end
