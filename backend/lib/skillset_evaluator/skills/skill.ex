defmodule SkillsetEvaluator.Skills.Skill do
  use Ecto.Schema
  import Ecto.Changeset

  schema "skills" do
    field :name, :string
    field :priority, :string
    field :position, :integer

    belongs_to :skill_group, SkillsetEvaluator.Skills.SkillGroup

    timestamps(type: :utc_datetime)
  end

  def changeset(skill, attrs) do
    skill
    |> cast(attrs, [:name, :priority, :position, :skill_group_id])
    |> validate_required([:name, :skill_group_id])
    |> validate_inclusion(:priority, ["low", "medium", "high", "critical"])
    |> foreign_key_constraint(:skill_group_id)
  end
end
