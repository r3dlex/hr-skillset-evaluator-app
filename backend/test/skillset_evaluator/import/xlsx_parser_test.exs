defmodule SkillsetEvaluator.Import.XlsxParserTest do
  use SkillsetEvaluator.DataCase

  alias SkillsetEvaluator.Import.XlsxParser

  @fixture_xlsx Path.join([__DIR__, "../../../..", "data", "SkillMatrix.xlsx"])
                |> Path.expand()

  # Skip xlsx tests if fixture file is unavailable (CI without data/ volume)
  defp fixture_available?, do: File.exists?(@fixture_xlsx)

  describe "parse/2" do
    test "returns error when file does not exist" do
      assert {:error, reason} = XlsxParser.parse("/nonexistent/path.xlsx", "2025-Q1")
      assert is_binary(reason)
    end

    test "returns ok with person rows when file is valid", _ctx do
      if fixture_available?() do
        assert {:ok, rows} = XlsxParser.parse(@fixture_xlsx, "2025-Q1")
        assert is_list(rows)
        # Should have at least one person row
        assert length(rows) > 0

        row = hd(rows)
        assert %XlsxParser.PersonRow{} = row
        assert is_binary(row.sheet_name)
        assert row.period == "2025-Q1"
        assert is_list(row.scores)
      else
        # When data/ file is not present, just verify the error handling
        assert {:error, _reason} = XlsxParser.parse("/nonexistent.xlsx", "2025-Q1")
      end
    end

    test "person rows have expected structure", _ctx do
      if fixture_available?() do
        {:ok, rows} = XlsxParser.parse(@fixture_xlsx, "2025-Q1")
        non_empty = Enum.reject(rows, fn r -> is_nil(r.name) or r.name == "" end)
        assert length(non_empty) > 0

        Enum.each(non_empty, fn row ->
          assert is_binary(row.name) or is_nil(row.name)
          assert is_binary(row.sheet_name)
          assert is_list(row.scores)

          Enum.each(row.scores, fn score ->
            assert Map.has_key?(score, :skill_name)
            assert Map.has_key?(score, :value)
            assert Map.has_key?(score, :priority)
            assert score.priority in ["critical", "high", "medium", "low"]
          end)
        end)
      end
    end

    test "handles non-xlsx file gracefully" do
      path = Path.join(System.tmp_dir!(), "test_#{System.unique_integer()}.xlsx")
      File.write!(path, "not valid xlsx content")
      on_exit(fn -> File.rm(path) end)

      # Should return an error, not raise
      result = XlsxParser.parse(path, "2025-Q1")
      assert {:error, _reason} = result
    end
  end

  describe "parse_skill_structures/1" do
    test "returns ok with empty list when file does not exist" do
      # parse_skill_structures rescues errors and returns {:ok, []}
      assert {:ok, structures} = XlsxParser.parse_skill_structures("/nonexistent/path.xlsx")
      assert structures == []
    end

    test "returns skill structure metadata from valid file", _ctx do
      if fixture_available?() do
        assert {:ok, structures} = XlsxParser.parse_skill_structures(@fixture_xlsx)
        assert is_list(structures)
        assert length(structures) > 0

        structure = hd(structures)
        assert Map.has_key?(structure, :sheet_name)
        assert Map.has_key?(structure, :groups)
        assert Map.has_key?(structure, :skills)
        assert is_binary(structure.sheet_name)
        assert is_list(structure.groups)
        assert is_list(structure.skills)
      end
    end

    test "skill structures have correct shape", _ctx do
      if fixture_available?() do
        {:ok, structures} = XlsxParser.parse_skill_structures(@fixture_xlsx)

        Enum.each(structures, fn s ->
          Enum.each(s.groups, fn g ->
            assert Map.has_key?(g, :name)
            assert Map.has_key?(g, :start_col)
            assert Map.has_key?(g, :end_col)
          end)

          Enum.each(s.skills, fn skill ->
            assert Map.has_key?(skill, :name)
            assert Map.has_key?(skill, :priority)
            assert Map.has_key?(skill, :column)
            assert skill.priority in ["critical", "high", "medium", "low"]
          end)
        end)
      end
    end
  end

  describe "parse_teams_sheet/1" do
    test "returns error when file does not exist" do
      assert {:error, reason} = XlsxParser.parse_teams_sheet("/nonexistent/path.xlsx")
      assert is_binary(reason)
    end

    test "returns ok with team data from valid file", _ctx do
      if fixture_available?() do
        assert {:ok, teams} = XlsxParser.parse_teams_sheet(@fixture_xlsx)
        assert is_list(teams)
      end
    end

    test "returns error for invalid xlsx content" do
      path = Path.join(System.tmp_dir!(), "test_#{System.unique_integer()}.xlsx")
      File.write!(path, "not valid xlsx")
      on_exit(fn -> File.rm(path) end)

      # Should return an error with message about parsing
      assert {:error, _reason} = XlsxParser.parse_teams_sheet(path)
    end
  end
end
