defmodule SkillsetEvaluator.Repo.Migrations.CreateGlossaryTerms do
  use Ecto.Migration

  def change do
    create table(:glossary_terms) do
      add :concept, :string, null: false
      add :domain, :string
      add :term_en, :string
      add :term_de, :string
      add :term_zh, :string
      add :term_pt_br, :string
      add :term_es, :string
      add :description_en, :text
      add :description_de, :text
      add :description_zh, :text
      add :source, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:glossary_terms, [:concept, :domain])
    create index(:glossary_terms, [:domain])
  end
end
