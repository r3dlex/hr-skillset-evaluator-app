defmodule SkillsetEvaluatorWeb.GapAnalysisJSON do
  def show(%{gap_analysis: gap_data}) do
    %{
      data:
        Enum.map(gap_data, fn item ->
          %{
            name: item.skill_name,
            skill_id: item.skill_id,
            manager_score: item.manager_score,
            self_score: item.self_score,
            gap: item.gap
          }
        end)
    }
  end
end
