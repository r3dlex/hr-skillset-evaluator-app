defmodule SkillsetEvaluatorWeb.ExportController do
  use SkillsetEvaluatorWeb, :controller

  alias SkillsetEvaluator.{Accounts, Export.XlsxWriter}

  def show(conn, %{"skillset_id" => skillset_id, "period" => period} = params) do
    user_ids =
      case params do
        %{"team_id" => team_id} ->
          team_id
          |> String.to_integer()
          |> Accounts.list_users_by_team()
          |> Enum.map(& &1.id)

        %{"user_ids" => ids} when is_binary(ids) ->
          ids |> String.split(",") |> Enum.map(&String.to_integer/1)

        _ ->
          [conn.assigns.current_user.id]
      end

    case XlsxWriter.generate(String.to_integer(skillset_id), period, user_ids) do
      {:ok, binary} ->
        conn
        |> put_resp_content_type(
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
        |> put_resp_header(
          "content-disposition",
          "attachment; filename=\"export_#{period}.xlsx\""
        )
        |> send_resp(200, binary)

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Export failed: #{inspect(reason)}"})
    end
  end

  def show(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameters: skillset_id, period"})
  end
end
