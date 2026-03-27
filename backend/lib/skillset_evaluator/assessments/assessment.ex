defmodule SkillsetEvaluator.Assessments.Assessment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "assessments" do
    field :name, :string
    field :description, :string

    belongs_to :created_by, SkillsetEvaluator.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(assessment, attrs) do
    assessment
    |> cast(attrs, [:name, :description, :created_by_id])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> unique_constraint(:name)
    |> foreign_key_constraint(:created_by_id)
  end
end
