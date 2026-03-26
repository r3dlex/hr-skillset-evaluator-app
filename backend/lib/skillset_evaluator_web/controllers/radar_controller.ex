defmodule SkillsetEvaluatorWeb.RadarController do
  use SkillsetEvaluatorWeb, :controller

  alias SkillsetEvaluator.Evaluations

  def show(conn, %{"skillset_id" => skillset_id, "period" => period} = params) do
    user_ids = parse_user_ids(params, conn)

    radar_data =
      case params do
        %{"skill_group_id" => group_id} ->
          Evaluations.get_radar_data_for_group(
            user_ids,
            String.to_integer(group_id),
            period
          )

        _ ->
          Evaluations.get_radar_data(user_ids, String.to_integer(skillset_id), period)
      end

    render(conn, :show, radar: radar_data)
  end

  def show(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameters: skillset_id, period"})
  end

  defp parse_user_ids(params, conn) do
    case params do
      %{"user_ids" => ids} when is_list(ids) ->
        Enum.map(ids, &String.to_integer/1)

      %{"user_ids" => ids} when is_binary(ids) ->
        ids |> String.split(",") |> Enum.map(&String.to_integer/1)

      _ ->
        [conn.assigns.current_user.id]
    end
  end
end
