defmodule SkillsetEvaluatorWeb.TeamController do
  use SkillsetEvaluatorWeb, :controller

  alias SkillsetEvaluator.Teams

  def index(conn, _params) do
    user = conn.assigns.current_user
    teams = Teams.list_teams_for_user(user)
    render(conn, :index, teams: teams)
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Teams.get_team(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Team not found."})

      team ->
        members = Teams.list_scoped_members(team.id, user)
        render(conn, :show, team: team, members: members)
    end
  end
end
