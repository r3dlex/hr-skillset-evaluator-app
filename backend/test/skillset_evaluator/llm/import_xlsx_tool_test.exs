defmodule SkillsetEvaluator.LLM.Tools.ImportXlsxTest do
  use SkillsetEvaluator.DataCase

  alias SkillsetEvaluator.LLM.Tools.ImportXlsx

  setup do
    manager = manager_fixture(%{name: "Tool Manager"})
    user = user_fixture(%{name: "Tool User", role: "user"})
    %{manager: manager, user: user}
  end

  describe "definition/0" do
    test "returns a map with name, description, and input_schema" do
      defn = ImportXlsx.definition()
      assert is_map(defn)
      assert defn.name == "import_xlsx"
      assert is_binary(defn.description)
      assert is_map(defn.input_schema)
      assert defn.input_schema.required == ["file_ref", "period"]
    end
  end

  describe "execute/2" do
    test "returns error when user is not manager or admin", ctx do
      result = ImportXlsx.execute(%{"file_ref" => "abc", "period" => "2025-Q1"}, ctx.user)
      assert {:error, msg} = result
      assert String.contains?(msg, "Manager") or String.contains?(msg, "Admin")
    end

    test "returns error when file_ref does not point to an existing file", ctx do
      result =
        ImportXlsx.execute(%{"file_ref" => "nonexistent_ref_xyz", "period" => "2025-Q1"}, ctx.manager)

      assert {:error, msg} = result
      assert String.contains?(msg, "File not found")
    end

    test "returns error for missing required parameters", ctx do
      result = ImportXlsx.execute(%{"period" => "2025-Q1"}, ctx.manager)
      assert {:error, msg} = result
      assert is_binary(msg)
    end

    test "returns error for completely empty params", ctx do
      result = ImportXlsx.execute(%{}, ctx.manager)
      assert {:error, _msg} = result
    end

    test "executes dry run when file exists and dry_run is true", ctx do
      file_ref = "test_dry_run_#{System.unique_integer()}"
      path = Path.join(System.tmp_dir!(), "chat_upload_#{file_ref}.xlsx")
      File.write!(path, "not real xlsx")
      on_exit(fn -> File.rm(path) end)

      result =
        ImportXlsx.execute(
          %{"file_ref" => file_ref, "period" => "2025-Q1", "dry_run" => true},
          ctx.manager
        )

      # Dry run with invalid xlsx returns an error from the parser
      assert {:error, _reason} = result
    end

    test "execute import when file exists (invalid content returns error)", ctx do
      file_ref = "test_import_#{System.unique_integer()}"
      path = Path.join(System.tmp_dir!(), "chat_upload_#{file_ref}.xlsx")
      File.write!(path, "not real xlsx")
      on_exit(fn -> File.rm(path) end)

      result =
        ImportXlsx.execute(
          %{"file_ref" => file_ref, "period" => "2025-Q1"},
          ctx.manager
        )

      # Import with invalid xlsx returns an error
      assert {:error, _reason} = result
    end
  end
end
