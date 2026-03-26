defmodule SkillsetEvaluator.Import.XlsxParser do
  @moduledoc """
  Parses xlsx files into structured messages for Broadway processing.

  The xlsx format has 3 header rows per skill sheet:
    Row 1: Skill group names (merged across columns)
    Row 2: Priority per skill (Critical/High/Medium)
    Row 3: Column headers (Team, Location, Role, Name/Skill, Skill1, Skill2, ...)
    Row 4+: Person data with scores
  """

  # Column E (0-indexed = 4)
  @skill_start_col 4

  defmodule SheetData do
    @moduledoc false
    defstruct [:sheet_name, :skill_groups, :skills, :person_rows]

    @type t :: %__MODULE__{
            sheet_name: String.t(),
            skill_groups: [%{name: String.t(), start_col: integer(), end_col: integer()}],
            skills: [
              %{name: String.t(), priority: String.t(), column: integer(), group_name: String.t()}
            ],
            person_rows: [
              %{
                team: String.t(),
                location: String.t(),
                role: String.t(),
                name: String.t(),
                scores: map()
              }
            ]
          }
  end

  defmodule PersonRow do
    @moduledoc false
    defstruct [:team, :location, :role, :name, :sheet_name, :scores, :period]

    @type t :: %__MODULE__{
            team: String.t(),
            location: String.t(),
            role: String.t(),
            name: String.t(),
            sheet_name: String.t(),
            scores: [
              %{
                skill_name: String.t(),
                group_name: String.t(),
                priority: String.t(),
                value: integer() | nil
              }
            ],
            period: String.t()
          }
  end

  @skip_sheets ["Info", "Teams"]

  @spec parse(String.t(), String.t()) :: {:ok, [PersonRow.t()]} | {:error, String.t()}
  def parse(file_path, period) do
    result = Xlsxir.multi_extract(file_path)
    table_ids = extract_table_ids(result)

    if table_ids == [] do
      {:error, "Failed to parse xlsx: no sheets found"}
    else
      person_rows =
        table_ids
        |> Enum.flat_map(fn table_id ->
          sheet_name = Xlsxir.get_info(table_id, :name)

          rows =
            if sheet_name in @skip_sheets do
              []
            else
              parse_skill_sheet(table_id, sheet_name, period)
            end

          Xlsxir.close(table_id)
          rows
        end)

      {:ok, person_rows}
    end
  rescue
    e -> {:error, "Xlsx parsing error: #{Exception.message(e)}"}
  end

  @spec parse_teams_sheet(String.t()) :: {:ok, [map()]} | {:error, String.t()}
  def parse_teams_sheet(file_path) do
    result = Xlsxir.multi_extract(file_path)
    table_ids = extract_table_ids(result)

    if table_ids == [] do
      {:error, "Failed to parse xlsx: no sheets found"}
    else
      teams_data =
        table_ids
        |> Enum.reduce([], fn table_id, acc ->
          sheet_name = Xlsxir.get_info(table_id, :name)

          result =
            if sheet_name == "Teams" do
              rows = Xlsxir.get_list(table_id)
              parse_teams_rows(rows)
            else
              []
            end

          Xlsxir.close(table_id)
          acc ++ result
        end)

      {:ok, teams_data}
    end
  end

  defp parse_skill_sheet(table_id, sheet_name, period) do
    rows = Xlsxir.get_list(table_id)

    case rows do
      [group_row, priority_row, header_row | data_rows] ->
        skill_groups = extract_skill_groups(group_row)
        skills = extract_skills(header_row, priority_row, skill_groups)

        data_rows
        |> Enum.reject(&empty_row?/1)
        |> Enum.map(fn row ->
          %PersonRow{
            team: safe_string(Enum.at(row, 0)),
            location: safe_string(Enum.at(row, 1)),
            role: safe_string(Enum.at(row, 2)),
            name: safe_string(Enum.at(row, 3)),
            sheet_name: sheet_name,
            period: period,
            scores: extract_scores(row, skills)
          }
        end)
        |> Enum.reject(fn pr -> pr.name == nil or pr.name == "" end)

      _ ->
        []
    end
  end

  defp extract_skill_groups(group_row) do
    group_row
    |> Enum.with_index()
    |> Enum.filter(fn {val, idx} -> idx >= @skill_start_col and val != nil and val != "" end)
    |> Enum.map(fn {name, col} -> %{name: safe_string(name), start_col: col} end)
    |> Enum.with_index()
    |> Enum.map(fn {group, _idx} ->
      next_group =
        Enum.at(
          group_row
          |> Enum.with_index()
          |> Enum.filter(fn {val, c} -> c > group.start_col and val != nil and val != "" end),
          0
        )

      end_col = if next_group, do: elem(next_group, 1) - 1, else: length(group_row) - 1
      Map.put(group, :end_col, end_col)
    end)
  end

  defp extract_skills(header_row, priority_row, skill_groups) do
    header_row
    |> Enum.with_index()
    |> Enum.filter(fn {val, idx} -> idx >= @skill_start_col and val != nil and val != "" end)
    |> Enum.map(fn {name, col} ->
      priority = safe_string(Enum.at(priority_row, col)) |> normalize_priority()
      group = find_group_for_column(skill_groups, col)

      %{
        name: safe_string(name),
        priority: priority,
        column: col,
        group_name: if(group, do: group.name, else: "Ungrouped")
      }
    end)
  end

  defp extract_scores(row, skills) do
    Enum.map(skills, fn skill ->
      raw_value = Enum.at(row, skill.column)

      %{
        skill_name: skill.name,
        group_name: skill.group_name,
        priority: skill.priority,
        value: parse_score(raw_value)
      }
    end)
  end

  defp find_group_for_column(groups, col) do
    Enum.find(groups, fn g -> col >= g.start_col and col <= g.end_col end)
  end

  defp parse_teams_rows([_header | data_rows]) do
    Enum.map(data_rows, fn row ->
      %{
        team: safe_string(Enum.at(row, 0)),
        name: safe_string(Enum.at(row, 1)),
        email: safe_string(Enum.at(row, 2)),
        username: safe_string(Enum.at(row, 3)),
        role: safe_string(Enum.at(row, 4)),
        location: safe_string(Enum.at(row, 5)),
        active: safe_string(Enum.at(row, 6)) in ["Yes", "yes", "Y", "TRUE", "true"]
      }
    end)
    |> Enum.reject(fn m -> m.name == nil or m.name == "" end)
  end

  defp parse_teams_rows(_), do: []

  defp parse_score(nil), do: nil
  defp parse_score(""), do: nil
  defp parse_score(val) when is_integer(val) and val >= 0 and val <= 5, do: val
  defp parse_score(val) when is_float(val), do: val |> round() |> min(5) |> max(0)

  defp parse_score(val) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} when n >= 0 and n <= 5 -> n
      _ -> nil
    end
  end

  defp parse_score(_), do: nil

  defp normalize_priority(nil), do: "medium"
  defp normalize_priority(""), do: "medium"

  defp normalize_priority(val) do
    case String.downcase(String.trim(to_string(val))) do
      v when v in ["critical", "c", "crit", "1"] -> "critical"
      v when v in ["high", "h", "2"] -> "high"
      v when v in ["medium", "m", "med", "3"] -> "medium"
      v when v in ["low", "l", "4"] -> "low"
      _ -> "medium"
    end
  end

  defp safe_string(nil), do: nil
  defp safe_string(val) when is_binary(val), do: String.trim(val)
  defp safe_string(val), do: to_string(val) |> String.trim()

  defp empty_row?(row) do
    Enum.all?(row, fn val -> val == nil or val == "" end)
  end

  # Xlsxir.multi_extract returns a keyword list [ok: ref, ok: ref, ...]
  # not {:ok, [ref, ref, ...]}. Extract the references.
  defp extract_table_ids(result) when is_list(result) do
    result
    |> Enum.filter(fn {status, _} -> status == :ok end)
    |> Enum.map(fn {:ok, ref} -> ref end)
  end

  defp extract_table_ids({:ok, table_ids}) when is_list(table_ids), do: table_ids
  defp extract_table_ids(_), do: []
end
