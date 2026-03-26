defmodule SkillsetEvaluatorWeb.GapAnalysisController do
  use SkillsetEvaluatorWeb, :controller

  alias SkillsetEvaluator.Evaluations

  def show(conn, %{"skillset_id" => skillset_id, "period" => period} = params) do
    user_id =
      case params do
        %{"user_id" => uid} -> String.to_integer(uid)
        _ -> conn.assigns.current_user.id
      end

    gap_data = Evaluations.get_gap_analysis(user_id, String.to_integer(skillset_id), period)
    render(conn, :show, gap_analysis: gap_data)
  end

  def show(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameters: skillset_id, period"})
  end
end
