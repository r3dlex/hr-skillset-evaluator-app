defmodule SkillsetEvaluatorWeb.MeController do
  use SkillsetEvaluatorWeb, :controller

  alias SkillsetEvaluator.Accounts
  alias SkillsetEvaluator.Accounts.User

  def show(conn, _params) do
    user =
      conn.assigns.current_user
      |> SkillsetEvaluator.Repo.preload(:team)

    team_data =
      if user.team do
        %{id: user.team.id, name: user.team.name}
      else
        nil
      end

    json(conn, %{
      data: %{
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        location: user.location,
        team: team_data,
        active: user.active,
        onboarding: %{
          completed_steps: User.completed_steps(user),
          dismissed: user.onboarding_dismissed
        }
      }
    })
  end

  def update_onboarding(conn, %{"step" => step_id}) when is_binary(step_id) do
    user = conn.assigns.current_user

    case Accounts.complete_onboarding_step(user, step_id) do
      {:ok, updated_user} ->
        conn
        |> put_status(:ok)
        |> json(%{
          completed_steps: User.completed_steps(updated_user),
          dismissed: updated_user.onboarding_dismissed
        })

      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to update onboarding"})
    end
  end

  def dismiss_onboarding(conn, _params) do
    user = conn.assigns.current_user

    case Accounts.dismiss_onboarding(user) do
      {:ok, _} ->
        conn |> put_status(:ok) |> json(%{dismissed: true})

      {:error, _} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "Failed to dismiss"})
    end
  end
end
