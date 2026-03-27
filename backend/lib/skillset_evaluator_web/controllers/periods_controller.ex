defmodule SkillsetEvaluatorWeb.PeriodsController do
  use SkillsetEvaluatorWeb, :controller

  alias SkillsetEvaluator.Evaluations
  alias SkillsetEvaluator.Teams

  def index(conn, params) do
    current_user = conn.assigns[:current_user]

    skillset_id = String.to_integer(params["skillset_id"] || "0")

    user_ids =
      cond do
        params["user_ids"] ->
          params["user_ids"]
          |> String.split(",")
          |> Enum.map(&String.to_integer/1)

        params["user_id"] ->
          [String.to_integer(params["user_id"])]

        params["team_id"] ->
          team_id = String.to_integer(params["team_id"])
          Teams.list_team_members(team_id) |> Enum.map(& &1.id)

        current_user ->
          [current_user.id]

        true ->
          []
      end

    periods = Evaluations.list_periods(user_ids, skillset_id)
    json(conn, %{data: periods})
  end
end
