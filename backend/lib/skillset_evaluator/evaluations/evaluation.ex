defmodule SkillsetEvaluator.Evaluations.Evaluation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "evaluations" do
    field :manager_score, :integer
    field :self_score, :integer
    field :period, :string
    field :notes, :string

    belongs_to :user, SkillsetEvaluator.Accounts.User
    belongs_to :skill, SkillsetEvaluator.Skills.Skill
    belongs_to :evaluated_by, SkillsetEvaluator.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(evaluation, attrs) do
    evaluation
    |> cast(attrs, [
      :manager_score,
      :self_score,
      :period,
      :notes,
      :user_id,
      :skill_id,
      :evaluated_by_id
    ])
    |> validate_required([:period, :user_id, :skill_id])
    |> validate_score(:manager_score)
    |> validate_score(:self_score)
    |> unique_constraint([:user_id, :skill_id, :period])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:skill_id)
    |> foreign_key_constraint(:evaluated_by_id)
  end

  defp validate_score(changeset, field) do
    validate_number(changeset, field,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 5
    )
  end
end
