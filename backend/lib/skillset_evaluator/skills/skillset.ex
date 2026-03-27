defmodule SkillsetEvaluator.Skills.Skillset do
  use Ecto.Schema
  import Ecto.Changeset

  schema "skillsets" do
    field :name, :string
    field :description, :string
    field :position, :integer
    field :applicable_roles, :string, default: "[]"

    field :skill_count, :integer, virtual: true

    has_many :skill_groups, SkillsetEvaluator.Skills.SkillGroup

    timestamps(type: :utc_datetime)
  end

  def changeset(skillset, attrs) do
    skillset
    |> cast(attrs, [:name, :description, :position, :applicable_roles])
    |> validate_required([:name])
  end

  @doc """
  Returns the list of applicable role strings, or empty list (meaning all roles).
  """
  def roles(%__MODULE__{applicable_roles: roles}) do
    case Jason.decode(roles || "[]") do
      {:ok, list} when is_list(list) -> list
      _ -> []
    end
  end
end
