defmodule SkillsetEvaluator.Skills do
  @moduledoc """
  The Skills context.
  """

  import Ecto.Query
  alias SkillsetEvaluator.Repo
  alias SkillsetEvaluator.Skills.{Skillset, SkillGroup, Skill}

  ## Skillsets

  def list_skillsets do
    Skillset
    |> order_by(:position)
    |> Repo.all()
  end

  def get_skillset(id) do
    Skillset
    |> Repo.get(id)
    |> Repo.preload(
      skill_groups:
        {from(sg in SkillGroup, order_by: sg.position),
         skills: from(s in Skill, order_by: s.position)}
    )
  end

  def get_skillset!(id) do
    Skillset
    |> Repo.get!(id)
    |> Repo.preload(
      skill_groups:
        {from(sg in SkillGroup, order_by: sg.position),
         skills: from(s in Skill, order_by: s.position)}
    )
  end

  def create_skillset(attrs) do
    %Skillset{}
    |> Skillset.changeset(attrs)
    |> Repo.insert()
  end

  def update_skillset(%Skillset{} = skillset, attrs) do
    skillset
    |> Skillset.changeset(attrs)
    |> Repo.update()
  end

  def delete_skillset(%Skillset{} = skillset) do
    Repo.delete(skillset)
  end

  ## Skill Groups

  def create_skill_group(attrs) do
    %SkillGroup{}
    |> SkillGroup.changeset(attrs)
    |> Repo.insert()
  end

  def update_skill_group(%SkillGroup{} = skill_group, attrs) do
    skill_group
    |> SkillGroup.changeset(attrs)
    |> Repo.update()
  end

  ## Skills

  def get_skill(id), do: Repo.get(Skill, id)

  def get_skill!(id), do: Repo.get!(Skill, id)

  def create_skill(attrs) do
    %Skill{}
    |> Skill.changeset(attrs)
    |> Repo.insert()
  end

  def update_skill(%Skill{} = skill, attrs) do
    skill
    |> Skill.changeset(attrs)
    |> Repo.update()
  end

  def list_skills_for_skillset(skillset_id) do
    Skill
    |> join(:inner, [s], sg in SkillGroup, on: s.skill_group_id == sg.id)
    |> where([s, sg], sg.skillset_id == ^skillset_id)
    |> order_by([s, sg], [sg.position, s.position])
    |> Repo.all()
  end
end
