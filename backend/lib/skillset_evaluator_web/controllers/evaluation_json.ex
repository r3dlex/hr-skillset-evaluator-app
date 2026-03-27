defmodule SkillsetEvaluatorWeb.EvaluationJSON do
  alias SkillsetEvaluator.Evaluations.Evaluation

  def index(%{evaluations: evaluations}) do
    %{data: Enum.map(evaluations, &evaluation_data/1)}
  end

  def show(%{evaluation: evaluation}) do
    %{data: evaluation_data(evaluation)}
  end

  defp evaluation_data(%Evaluation{} = eval) do
    %{
      id: eval.id,
      skill_id: eval.skill_id,
      user_id: eval.user_id,
      manager_score: eval.manager_score,
      self_score: eval.self_score,
      period: eval.period,
      assessment_id: eval.assessment_id,
      notes: eval.notes,
      evaluated_by_id: eval.evaluated_by_id
    }
  end
end
