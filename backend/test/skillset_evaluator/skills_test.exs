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

    test "includes skill_count for each skillset" do
      skillset = skillset_fixture(%{name: "With Skills", position: 1})
      group = skill_group_fixture(%{skillset_id: skillset.id})
      skill_fixture(%{skill_group_id: group.id})
      skill_fixture(%{skill_group_id: group.id})

      skillsets = Skills.list_skillsets()
      found = Enum.find(skillsets, fn s -> s.id == skillset.id end)
      assert found.skill_count == 2
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

  describe "get_skillset!/1" do
    test "returns the skillset" do
      skillset = skillset_fixture()
      result = Skills.get_skillset!(skillset.id)
      assert result.id == skillset.id
    end

    test "raises for non-existent id" do
      assert_raise Ecto.NoResultsError, fn -> Skills.get_skillset!(0) end
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

  describe "update_skillset/2" do
    test "updates name and description" do
      skillset = skillset_fixture(%{name: "Old Name"})
      assert {:ok, updated} = Skills.update_skillset(skillset, %{name: "New Name"})
      assert updated.name == "New Name"
    end

    test "returns error changeset with blank name" do
      skillset = skillset_fixture()
      assert {:error, changeset} = Skills.update_skillset(skillset, %{name: ""})
      assert %{name: _} = errors_on(changeset)
    end
  end

  describe "delete_skillset/1" do
    test "deletes the skillset" do
      skillset = skillset_fixture()
      assert {:ok, _} = Skills.delete_skillset(skillset)
      assert is_nil(Skills.get_skillset(skillset.id))
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

    test "returns error with missing name" do
      skillset = skillset_fixture()
      assert {:error, changeset} = Skills.create_skill_group(%{skillset_id: skillset.id})
      assert %{name: _} = errors_on(changeset)
    end
  end

  describe "update_skill_group/2" do
    test "updates the skill group name" do
      group = skill_group_fixture(%{name: "Old Group"})
      assert {:ok, updated} = Skills.update_skill_group(group, %{name: "New Group"})
      assert updated.name == "New Group"
    end

    test "returns error changeset with blank name" do
      group = skill_group_fixture()
      assert {:error, changeset} = Skills.update_skill_group(group, %{name: ""})
      assert %{name: _} = errors_on(changeset)
    end
  end

  describe "get_skill/1" do
    test "returns the skill when it exists" do
      skill = skill_fixture(%{name: "Kubernetes"})
      result = Skills.get_skill(skill.id)
      assert result.id == skill.id
      assert result.name == "Kubernetes"
    end

    test "returns nil for non-existent id" do
      assert is_nil(Skills.get_skill(0))
    end
  end

  describe "get_skill!/1" do
    test "returns the skill" do
      skill = skill_fixture()
      result = Skills.get_skill!(skill.id)
      assert result.id == skill.id
    end

    test "raises for non-existent id" do
      assert_raise Ecto.NoResultsError, fn -> Skills.get_skill!(0) end
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

    test "returns error with missing name" do
      group = skill_group_fixture()
      assert {:error, changeset} = Skills.create_skill(%{skill_group_id: group.id})
      assert %{name: _} = errors_on(changeset)
    end
  end

  describe "update_skill/2" do
    test "updates skill name and priority" do
      skill = skill_fixture(%{name: "Old Skill", priority: "low"})
      assert {:ok, updated} = Skills.update_skill(skill, %{name: "New Skill", priority: "high"})
      assert updated.name == "New Skill"
      assert updated.priority == "high"
    end

    test "returns error changeset with blank name" do
      skill = skill_fixture()
      assert {:error, changeset} = Skills.update_skill(skill, %{name: ""})
      assert %{name: _} = errors_on(changeset)
    end
  end

  describe "list_skills_for_skillset/1" do
    test "returns skills across all groups ordered by group + skill position" do
      skillset = skillset_fixture()
      g1 = skill_group_fixture(%{skillset_id: skillset.id, position: 1})
      g2 = skill_group_fixture(%{skillset_id: skillset.id, position: 2})
      s1 = skill_fixture(%{skill_group_id: g1.id, name: "A", position: 1})
      s2 = skill_fixture(%{skill_group_id: g2.id, name: "B", position: 1})

      skills = Skills.list_skills_for_skillset(skillset.id)
      ids = Enum.map(skills, & &1.id)

      assert s1.id in ids
      assert s2.id in ids
    end

    test "returns empty list for skillset with no groups" do
      skillset = skillset_fixture()
      assert Skills.list_skills_for_skillset(skillset.id) == []
    end
  end
end
