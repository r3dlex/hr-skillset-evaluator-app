defmodule SkillsetEvaluator.Fixtures do
  @moduledoc """
  Factory functions for test fixtures.
  """

  alias SkillsetEvaluator.Repo
  alias SkillsetEvaluator.Accounts.User
  alias SkillsetEvaluator.Teams.Team
  alias SkillsetEvaluator.Skills.{Skillset, SkillGroup, Skill}
  alias SkillsetEvaluator.Evaluations.Evaluation

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  def valid_user_password, do: "password123!"

  def user_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        email: unique_user_email(),
        password: valid_user_password(),
        name: "Test User",
        role: "user"
      })

    {:ok, user} =
      %User{}
      |> User.registration_changeset(attrs)
      |> Repo.insert()

    user
  end

  def manager_fixture(attrs \\ %{}) do
    user_fixture(Map.merge(%{role: "manager"}, attrs))
  end

  def team_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Team #{System.unique_integer()}"
      })

    {:ok, team} =
      %Team{}
      |> Team.changeset(attrs)
      |> Repo.insert()

    team
  end

  def skillset_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Skillset #{System.unique_integer()}",
        description: "A test skillset",
        position: 1
      })

    {:ok, skillset} =
      %Skillset{}
      |> Skillset.changeset(attrs)
      |> Repo.insert()

    skillset
  end

  def skill_group_fixture(attrs \\ %{}) do
    skillset = Map.get_lazy(attrs, :skillset, fn -> skillset_fixture() end)

    attrs =
      attrs
      |> Map.delete(:skillset)
      |> Enum.into(%{
        name: "Group #{System.unique_integer()}",
        position: 1,
        skillset_id: skillset.id
      })

    {:ok, skill_group} =
      %SkillGroup{}
      |> SkillGroup.changeset(attrs)
      |> Repo.insert()

    skill_group
  end

  def skill_fixture(attrs \\ %{}) do
    skill_group = Map.get_lazy(attrs, :skill_group, fn -> skill_group_fixture() end)

    attrs =
      attrs
      |> Map.delete(:skill_group)
      |> Enum.into(%{
        name: "Skill #{System.unique_integer()}",
        priority: "medium",
        position: 1,
        skill_group_id: skill_group.id
      })

    {:ok, skill} =
      %Skill{}
      |> Skill.changeset(attrs)
      |> Repo.insert()

    skill
  end

  def evaluation_fixture(attrs \\ %{}) do
    user = Map.get_lazy(attrs, :user, fn -> user_fixture() end)
    skill = Map.get_lazy(attrs, :skill, fn -> skill_fixture() end)

    attrs =
      attrs
      |> Map.delete(:user)
      |> Map.delete(:skill)
      |> Enum.into(%{
        user_id: user.id,
        skill_id: skill.id,
        period: "2025-Q1",
        manager_score: 3,
        self_score: 4
      })

    {:ok, evaluation} =
      %Evaluation{}
      |> Evaluation.changeset(attrs)
      |> Repo.insert()

    evaluation
  end
end
