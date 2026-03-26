defmodule SkillsetEvaluatorWeb.GapAnalysisJSON do
  def show(%{gap_analysis: gap_data}) do
    %{data: gap_data}
  end
end
