defmodule SkillsetEvaluatorWeb.TeamJSON do
  alias SkillsetEvaluator.Teams.Team
  alias SkillsetEvaluator.Accounts.User

  def index(%{teams: teams}) do
    %{data: Enum.map(teams, &team_data/1)}
  end

  def show(%{team: team, members: members}) do
    %{
      data:
        team_data(team)
        |> Map.put(:members, Enum.map(members, &member_data/1))
    }
  end

  defp team_data(%Team{} = team) do
    data = %{
      id: team.id,
      name: team.name
    }

    case Map.get(team, :member_count) do
      nil -> data
      count -> Map.put(data, :member_count, count)
    end
  end

  defp member_data(%User{} = user) do
    %{
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      location: user.location,
      active: user.active
    }
  end
end
