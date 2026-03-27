defmodule SkillsetEvaluatorWeb.GapAnalysisController do
  use SkillsetEvaluatorWeb, :controller

  alias SkillsetEvaluator.Evaluations

  def show(conn, %{"skillset_id" => skillset_id, "period" => period} = params) do
    user_id =
      case params do
        %{"user_id" => uid} -> String.to_integer(uid)
        _ -> conn.assigns.current_user.id
      end

    opts =
      []
      |> add_if(params["team_id"], fn v -> {:team_id, String.to_integer(v)} end)
      |> add_if(params["location"], fn v -> {:location, v} end)

    gap_data =
      Evaluations.get_gap_analysis(user_id, String.to_integer(skillset_id), period, opts)

    render(conn, :show, gap_analysis: gap_data)
  end

  def show(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameters: skillset_id, period"})
  end

  defp add_if(opts, nil, _fun), do: opts
  defp add_if(opts, "", _fun), do: opts
  defp add_if(opts, val, fun), do: [fun.(val) | opts]
end
