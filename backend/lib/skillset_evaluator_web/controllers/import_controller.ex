defmodule SkillsetEvaluatorWeb.ImportController do
  use SkillsetEvaluatorWeb, :controller

  alias SkillsetEvaluator.Import.Pipeline

  def create(conn, %{"file" => %Plug.Upload{path: path, filename: filename}} = params) do
    unless String.ends_with?(filename, ".xlsx") do
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Only .xlsx files are supported."})
    else
      period = Map.get(params, "period", default_period())
      evaluator = conn.assigns.current_user

      case Pipeline.run_import(path, period, evaluator.id) do
        {:ok, summary} ->
          conn
          |> put_status(:ok)
          |> json(%{data: summary})

        {:error, reason} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: reason})
      end
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing file upload. Send multipart with 'file' field."})
  end

  defp default_period do
    now = Date.utc_today()
    quarter = div(now.month - 1, 3) + 1
    "#{now.year}-Q#{quarter}"
  end
end
