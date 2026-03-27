defmodule SkillsetEvaluator.Glossary.Term do
  use Ecto.Schema
  import Ecto.Changeset

  schema "glossary_terms" do
    field :concept, :string
    field :domain, :string
    field :term_en, :string
    field :term_de, :string
    field :term_zh, :string
    field :term_pt_br, :string
    field :term_es, :string
    field :description_en, :string
    field :description_de, :string
    field :description_zh, :string
    field :source, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(term, attrs) do
    term
    |> cast(attrs, [
      :concept,
      :domain,
      :term_en,
      :term_de,
      :term_zh,
      :term_pt_br,
      :term_es,
      :description_en,
      :description_de,
      :description_zh,
      :source
    ])
    |> validate_required([:concept])
    |> unique_constraint([:concept, :domain])
  end
end
