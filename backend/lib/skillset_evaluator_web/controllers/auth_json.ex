defmodule SkillsetEvaluatorWeb.AuthJSON do
  alias SkillsetEvaluator.Accounts.User

  def user(%{user: user}) do
    %{data: user_data(user)}
  end

  defp user_data(%User{} = user) do
    %{
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      job_title: user.job_title,
      location: user.location,
      team_id: user.team_id,
      active: user.active
    }
  end
end
