defmodule SkillsetEvaluator.LLM.Tools.ImportXlsx do
  @moduledoc """
  Tool definition for the Anthropic tool_use API that enables
  importing skill evaluation data from an uploaded SkillMatrix.xlsx file.
  Only available to Manager and Admin roles.
  """

  @tool_definition %{
    name: "import_xlsx",
    description:
      "Import skill evaluation data from an uploaded SkillMatrix.xlsx file into the database. Only available to Manager and Admin roles.",
    input_schema: %{
      type: "object",
      properties: %{
        file_ref: %{type: "string", description: "Reference to the uploaded xlsx file"},
        period: %{type: "string", description: "Evaluation period, e.g. '2026-Q1'"},
        dry_run: %{
          type: "boolean",
          description: "If true, validate only without writing to database"
        }
      },
      required: ["file_ref", "period"]
    }
  }

  @doc """
  Returns the tool definition map for Anthropic tool_use API registration.
  """
  def definition, do: @tool_definition

  @doc """
  Executes the import_xlsx tool with the given parameters and user context.
  """
  def execute(%{"file_ref" => file_ref, "period" => period} = params, user) do
    if user.role in ["manager", "admin"] do
      dry_run = Map.get(params, "dry_run", false)
      file_path = get_temp_file_path(file_ref)

      if file_path && File.exists?(file_path) do
        if dry_run do
          execute_dry_run(file_path, period)
        else
          execute_import(file_path, period, user.id)
        end
      else
        {:error, "File not found. Please upload the xlsx file first."}
      end
    else
      {:error, "Only Managers and Admins can import evaluation data."}
    end
  end

  def execute(_params, _user) do
    {:error, "Missing required parameters: file_ref and period."}
  end

  defp execute_import(file_path, period, user_id) do
    case SkillsetEvaluator.Import.Pipeline.run_import(file_path, period, user_id) do
      {:ok, summary} ->
        error_count = length(Map.get(summary, :errors, []))

        {:ok,
         "Import completed. #{summary.rows_processed} rows processed, " <>
           "#{summary.evaluations_created} evaluations created, " <>
           "#{summary.evaluations_updated} updated. #{error_count} errors."}

      {:error, reason} ->
        {:error, "Import failed: #{reason}"}
    end
  end

  defp execute_dry_run(file_path, period) do
    # Validate the file can be parsed without writing to DB
    case SkillsetEvaluator.Import.XlsxParser.parse(file_path, period) do
      {:ok, person_rows} ->
        {:ok,
         "Dry run successful. Found #{length(person_rows)} person rows ready for import. " <>
           "No data was written to the database."}

      {:error, reason} ->
        {:error, "Dry run validation failed: #{reason}"}
    end
  end

  defp get_temp_file_path(file_ref) do
    Path.join(System.tmp_dir!(), "chat_upload_#{file_ref}.xlsx")
  end
end
