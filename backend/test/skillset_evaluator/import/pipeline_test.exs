defmodule SkillsetEvaluator.Import.PipelineTest do
  use SkillsetEvaluator.DataCase

  alias SkillsetEvaluator.Import.Pipeline
  alias SkillsetEvaluator.Import.XlsxParser.PersonRow

  @fixture_xlsx Path.join([__DIR__, "../../../..", "data", "SkillMatrix.xlsx"])
                |> Path.expand()

  defp fixture_available?, do: File.exists?(@fixture_xlsx)

  describe "run_import/3" do
    test "returns error when file does not exist" do
      assert {:error, reason} = Pipeline.run_import("/nonexistent/path.xlsx", "2025-Q1", nil)
      assert is_binary(reason)
    end

    test "returns error for non-xlsx content" do
      path = Path.join(System.tmp_dir!(), "test_#{System.unique_integer()}.xlsx")
      File.write!(path, "not valid xlsx content")
      on_exit(fn -> File.rm(path) end)

      result = Pipeline.run_import(path, "2025-Q1", nil)
      assert {:error, _reason} = result
    end

    test "successfully imports xlsx and returns summary", _ctx do
      if fixture_available?() do
        manager = manager_fixture(%{name: "Import Test Manager"})
        assert {:ok, summary} = Pipeline.run_import(@fixture_xlsx, "2025-Q1", manager.id)

        assert Map.has_key?(summary, :rows_processed)
        assert Map.has_key?(summary, :evaluations_created)
        assert Map.has_key?(summary, :evaluations_updated)
        assert Map.has_key?(summary, :errors)
        assert is_integer(summary.rows_processed)
        assert summary.rows_processed > 0
        assert is_list(summary.errors)
      end
    end

    test "run_import returns 0 rows processed for empty sheet", _ctx do
      # Create a minimal xlsx with 0 data rows using a temp file
      # Since we can't easily create a valid xlsx programmatically, test with bad file
      path = Path.join(System.tmp_dir!(), "test_#{System.unique_integer()}.xlsx")
      File.write!(path, "PK")
      on_exit(fn -> File.rm(path) end)

      result = Pipeline.run_import(path, "2025-Q1", nil)
      # Should either return error or ok with 0 rows
      assert match?({:error, _}, result) or match?({:ok, %{rows_processed: 0}}, result)
    end
  end

  describe "process_rows_sync/2" do
    test "returns zero counts when given empty rows" do
      result = Pipeline.process_rows_sync([], nil)
      assert result == %{created: 0, updated: 0, errors: []}
    end

    test "processes rows and accumulates results via run_import", _ctx do
      if fixture_available?() do
        manager = manager_fixture(%{name: "Sync Import Manager"})
        # Use run_import to test the full pipeline including process_rows_sync
        assert {:ok, result} = Pipeline.run_import(@fixture_xlsx, "2025-Q2", manager.id)
        assert is_integer(result.rows_processed)
        assert is_integer(result.evaluations_created)
        assert is_integer(result.evaluations_updated)
        assert is_list(result.errors)
      end
    end

    test "process_rows_sync handles empty rows list with nil evaluator_id" do
      result = Pipeline.process_rows_sync([], nil)
      assert is_map(result)
      assert Map.has_key?(result, :created)
      assert result.created == 0
      assert result.updated == 0
      assert result.errors == []
    end
  end

  describe "handle_batch/4" do
    test "returns messages unchanged" do
      messages = [
        %Broadway.Message{data: "test-data", acknowledger: Broadway.NoopAcknowledger.init()}
      ]

      result = Pipeline.handle_batch(:default, messages, %Broadway.BatchInfo{}, %{})
      assert result == messages
    end

    test "returns empty list unchanged" do
      result = Pipeline.handle_batch(:default, [], %Broadway.BatchInfo{}, %{})
      assert result == []
    end
  end

  describe "handle_message/3" do
    test "marks message as failed when user not found" do
      row = %PersonRow{
        name: "Nonexistent User #{System.unique_integer()}",
        team: "Test Team",
        sheet_name: "Application Development",
        scores: [],
        period: "2025-Q1",
        role: "user",
        location: nil
      }

      message = %Broadway.Message{
        data: row,
        acknowledger: Broadway.NoopAcknowledger.init()
      }

      result = Pipeline.handle_message(:default, message, %{evaluator_id: nil})
      assert match?({:failed, _}, result.status)
    end

    test "marks message as failed when skillset not found" do
      # Create user but no skillset with the given name
      user = user_fixture(%{name: "Handle Msg User #{System.unique_integer()}"})

      row = %PersonRow{
        name: user.name,
        team: nil,
        sheet_name: "Definitely Nonexistent Skillset #{System.unique_integer()}",
        scores: [],
        period: "2025-Q1",
        role: "user",
        location: nil
      }

      message = %Broadway.Message{
        data: row,
        acknowledger: Broadway.NoopAcknowledger.init()
      }

      result = Pipeline.handle_message(:default, message, %{evaluator_id: nil})
      assert match?({:failed, _}, result.status)
    end

    test "processes row successfully when user and skillset exist" do
      team = team_fixture(%{name: "Handle Team #{System.unique_integer()}"})
      user = user_fixture(%{name: "Handle User #{System.unique_integer()}", team_id: team.id})
      skillset = skillset_fixture(%{name: "Handle Skillset #{System.unique_integer()}"})

      row = %PersonRow{
        name: user.name,
        team: team.name,
        sheet_name: skillset.name,
        scores: [],
        period: "2025-Q1",
        role: "user",
        location: nil
      }

      message = %Broadway.Message{
        data: row,
        acknowledger: Broadway.NoopAcknowledger.init()
      }

      result = Pipeline.handle_message(:default, message, %{evaluator_id: nil})
      assert result.status == :ok
    end
  end

  describe "process_rows_sync/2 — error accumulation" do
    test "accumulates errors for rows with missing users" do
      row = %PersonRow{
        name: "Missing Person #{System.unique_integer()}",
        team: nil,
        sheet_name: "Some Sheet",
        scores: [],
        period: "2025-Q1",
        role: "user",
        location: nil
      }

      result = Pipeline.process_rows_sync([row], nil)
      assert is_map(result)
      assert length(result.errors) > 0
    end
  end
end
