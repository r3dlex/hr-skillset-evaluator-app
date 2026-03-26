defmodule SkillsetEvaluator.Teams.Team do
  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :name, :string

    has_many :users, SkillsetEvaluator.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
