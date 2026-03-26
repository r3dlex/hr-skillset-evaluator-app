defmodule SkillsetEvaluatorWeb.MeController do
  use SkillsetEvaluatorWeb, :controller

  def show(conn, _params) do
    user = conn.assigns.current_user

    json(conn, %{
      data: %{
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        location: user.location,
        team_id: user.team_id,
        active: user.active
      }
    })
  end
end
