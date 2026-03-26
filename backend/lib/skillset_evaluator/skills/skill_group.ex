defmodule SkillsetEvaluator.Skills.SkillGroup do
  use Ecto.Schema
  import Ecto.Changeset

  schema "skill_groups" do
    field :name, :string
    field :position, :integer

    belongs_to :skillset, SkillsetEvaluator.Skills.Skillset
    has_many :skills, SkillsetEvaluator.Skills.Skill

    timestamps(type: :utc_datetime)
  end

  def changeset(skill_group, attrs) do
    skill_group
    |> cast(attrs, [:name, :position, :skillset_id])
    |> validate_required([:name, :skillset_id])
    |> foreign_key_constraint(:skillset_id)
  end
end
