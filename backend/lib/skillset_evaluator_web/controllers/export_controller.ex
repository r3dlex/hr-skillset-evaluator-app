defmodule SkillsetEvaluatorWeb.ExportController do
  use SkillsetEvaluatorWeb, :controller

  alias SkillsetEvaluator.{Evaluations, Skills, Accounts}

  def show(conn, %{"skillset_id" => skillset_id, "period" => period} = params) do
    skillset = Skills.get_skillset!(String.to_integer(skillset_id))

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

    skills =
      skillset.skill_groups
      |> Enum.flat_map(fn sg -> sg.skills end)

    header = ["Email", "Name"] ++ Enum.map(skills, & &1.name)

    rows =
      Enum.map(user_ids, fn uid ->
        user = Accounts.get_user!(uid)
        evals = Evaluations.list_evaluations(uid, String.to_integer(skillset_id), period)

        scores =
          Enum.map(skills, fn skill ->
            eval = Enum.find(evals, &(&1.skill_id == skill.id))

            if eval do
              "M:#{eval.manager_score || "-"}/S:#{eval.self_score || "-"}"
            else
              "-"
            end
          end)

        [user.email, user.name || ""] ++ scores
      end)

    csv_content =
      [header | rows]
      |> Enum.map(&Enum.join(&1, ","))
      |> Enum.join("\n")

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"export_#{period}.csv\"")
    |> send_resp(200, csv_content)
  end

  def show(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameters: skillset_id, period"})
  end
end
