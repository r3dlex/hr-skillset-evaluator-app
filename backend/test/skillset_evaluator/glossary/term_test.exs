defmodule SkillsetEvaluator.Glossary.TermTest do
  use SkillsetEvaluator.DataCase

  alias SkillsetEvaluator.Glossary.Term

  describe "changeset/2" do
    test "valid changeset with required concept" do
      changeset =
        Term.changeset(%Term{}, %{
          concept: "AEC",
          domain: "construction",
          term_en: "Architecture Engineering Construction",
          term_de: "Architektur Ingenieur Bau"
        })

      assert changeset.valid?
    end

    test "invalid without concept" do
      changeset = Term.changeset(%Term{}, %{domain: "test"})
      assert %{concept: _} = errors_on(changeset)
    end

    test "casts all multilingual fields" do
      attrs = %{
        concept: "BIM",
        domain: "software",
        term_en: "Building Information Modeling",
        term_de: "Gebäudeinformationsmodell",
        term_zh: "建筑信息模型",
        term_pt_br: "Modelagem de Informações da Construção",
        term_es: "Modelado de Información de Construcción",
        description_en: "Digital representation of physical building",
        description_de: "Digitale Darstellung",
        description_zh: "数字化表示",
        source: "ISO 19650"
      }

      changeset = Term.changeset(%Term{}, attrs)
      assert changeset.valid?
    end
  end
end
