defmodule SkillsetEvaluator.Skills.Skillset do
  use Ecto.Schema
  import Ecto.Changeset

  schema "skillsets" do
    field :name, :string
    field :description, :string
    field :position, :integer

    has_many :skill_groups, SkillsetEvaluator.Skills.SkillGroup

    timestamps(type: :utc_datetime)
  end

  def changeset(skillset, attrs) do
    skillset
    |> cast(attrs, [:name, :description, :position])
    |> validate_required([:name])
  end
end
