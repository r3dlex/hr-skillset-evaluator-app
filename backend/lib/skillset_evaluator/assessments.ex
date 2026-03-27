defmodule SkillsetEvaluator.Assessments do
  @moduledoc """
  The Assessments context.
  """

  import Ecto.Query
  alias SkillsetEvaluator.Repo
  alias SkillsetEvaluator.Assessments.Assessment

  def list_assessments do
    Assessment
    |> order_by([a], desc: a.inserted_at)
    |> Repo.all()
  end

  @doc """
  List assessments that have evaluations for the given users and skillset.
  """
  def list_assessments_with_data(user_ids, skillset_id)
      when is_list(user_ids) and length(user_ids) > 0 do
    skill_ids = skill_ids_for_skillset(skillset_id)

    Assessment
    |> join(:inner, [a], e in SkillsetEvaluator.Evaluations.Evaluation,
      on: e.assessment_id == a.id
    )
    |> where([a, e], e.user_id in ^user_ids and e.skill_id in ^skill_ids)
    |> distinct([a], a.id)
    |> order_by([a], desc: a.inserted_at)
    |> Repo.all()
  end

  def list_assessments_with_data(_user_ids, _skillset_id), do: []

  def get_assessment(id), do: Repo.get(Assessment, id)

  def get_assessment_by_name(name), do: Repo.get_by(Assessment, name: name)

  def create_assessment(attrs, created_by) do
    %Assessment{}
    |> Assessment.changeset(Map.put(attrs, :created_by_id, created_by.id))
    |> Repo.insert()
  end

  @doc """
  Find or create an assessment by name. Used during imports and evaluations
  so that a period string can transparently become an assessment.
  """
  def find_or_create_assessment(name, created_by \\ nil) do
    case get_assessment_by_name(name) do
      %Assessment{} = a ->
        {:ok, a}

      nil ->
        attrs = %{name: name}
        attrs = if created_by, do: Map.put(attrs, :created_by_id, created_by.id), else: attrs

        %Assessment{}
        |> Assessment.changeset(attrs)
        |> Repo.insert()
    end
  end

  defp skill_ids_for_skillset(skillset_id) do
    alias SkillsetEvaluator.Skills.{Skill, SkillGroup}

    Skill
    |> join(:inner, [s], sg in SkillGroup, on: s.skill_group_id == sg.id)
    |> where([s, sg], sg.skillset_id == ^skillset_id)
    |> select([s], s.id)
    |> Repo.all()
  end
end
