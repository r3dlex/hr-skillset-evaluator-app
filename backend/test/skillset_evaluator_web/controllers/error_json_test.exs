defmodule SkillsetEvaluatorWeb.ErrorJSONTest do
  use SkillsetEvaluatorWeb.ConnCase, async: true

  alias SkillsetEvaluatorWeb.ErrorJSON

  test "renders 404.json" do
    assert %{errors: %{detail: "Not Found"}} = ErrorJSON.render("404.json", %{})
  end

  test "renders 500.json" do
    assert %{errors: %{detail: "Internal Server Error"}} = ErrorJSON.render("500.json", %{})
  end

  test "renders generic error for unknown template" do
    result = ErrorJSON.render("403.json", %{})
    assert %{errors: %{detail: _detail}} = result
  end
end
