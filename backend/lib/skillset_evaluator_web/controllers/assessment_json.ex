defmodule SkillsetEvaluatorWeb.AssessmentJSON do
  alias SkillsetEvaluator.Assessments.Assessment

  def index(%{assessments: assessments}) do
    %{data: Enum.map(assessments, &assessment_data/1)}
  end

  def show(%{assessment: assessment}) do
    %{data: assessment_data(assessment)}
  end

  defp assessment_data(%Assessment{} = a) do
    %{
      id: a.id,
      name: a.name,
      description: a.description,
      created_by_id: a.created_by_id,
      inserted_at: a.inserted_at,
      updated_at: a.updated_at
    }
  end
end
