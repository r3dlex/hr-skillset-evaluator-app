defmodule SkillsetEvaluatorWeb.TeamController do
  use SkillsetEvaluatorWeb, :controller

  alias SkillsetEvaluator.Teams

  def index(conn, _params) do
    teams = Teams.list_teams_with_member_count()
    render(conn, :index, teams: teams)
  end

  def show(conn, %{"id" => id}) do
    case Teams.get_team(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Team not found."})

      team ->
        members = Teams.list_team_members(team.id)
        render(conn, :show, team: team, members: members)
    end
  end
end
