defmodule SkillsetEvaluatorWeb.EvaluationController do
  use SkillsetEvaluatorWeb, :controller

  alias SkillsetEvaluator.Evaluations

  def index(conn, %{"user_id" => user_id, "skillset_id" => skillset_id, "period" => period}) do
    evaluations = Evaluations.list_evaluations(user_id, skillset_id, period)
    render(conn, :index, evaluations: evaluations)
  end

  def index(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameters: user_id, skillset_id, period"})
  end

  def update_manager_scores(conn, %{"user_id" => user_id, "period" => period, "scores" => scores}) do
    evaluator = conn.assigns.current_user

    scores_list =
      Enum.map(scores, fn s ->
        %{
          skill_id: s["skill_id"],
          score: s["score"],
          notes: s["notes"]
        }
      end)

    case Evaluations.upsert_manager_scores(evaluator, user_id, period, scores_list) do
      {:ok, evaluations} ->
        render(conn, :index, evaluations: evaluations)

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: inspect(reason)})
    end
  end

  def update_self_scores(conn, %{"period" => period, "scores" => scores}) do
    user = conn.assigns.current_user

    scores_list =
      Enum.map(scores, fn s ->
        %{
          skill_id: s["skill_id"],
          score: s["score"]
        }
      end)

    case Evaluations.upsert_self_scores(user.id, period, scores_list) do
      {:ok, evaluations} ->
        render(conn, :index, evaluations: evaluations)

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: inspect(reason)})
    end
  end
end
