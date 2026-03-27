defmodule SkillsetEvaluatorWeb.SkillsetJSON do
  alias SkillsetEvaluator.Skills.{Skillset, SkillGroup, Skill}

  def index(%{skillsets: skillsets}) do
    %{data: Enum.map(skillsets, &skillset_summary/1)}
  end

  def show(%{skillset: skillset}) do
    %{data: skillset_detail(skillset)}
  end

  defp skillset_summary(%Skillset{} = skillset) do
    %{
      id: skillset.id,
      name: skillset.name,
      description: skillset.description,
      position: skillset.position,
      applicable_roles: Skillset.roles(skillset)
    }
  end

  defp skillset_detail(%Skillset{} = skillset) do
    base = skillset_summary(skillset)

    skill_groups =
      case skillset.skill_groups do
        %Ecto.Association.NotLoaded{} -> []
        groups -> Enum.map(groups, &skill_group_data/1)
      end

    Map.put(base, :skill_groups, skill_groups)
  end

  defp skill_group_data(%SkillGroup{} = group) do
    skills =
      case group.skills do
        %Ecto.Association.NotLoaded{} -> []
        skills -> Enum.map(skills, &skill_data/1)
      end

    %{
      id: group.id,
      name: group.name,
      position: group.position,
      skills: skills
    }
  end

  defp skill_data(%Skill{} = skill) do
    %{
      id: skill.id,
      name: skill.name,
      priority: skill.priority,
      position: skill.position
    }
  end
end
