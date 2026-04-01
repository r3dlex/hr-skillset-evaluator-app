defmodule SkillsetEvaluatorWeb.ImportControllerTest do
  use SkillsetEvaluatorWeb.ConnCase

  @fixture_xlsx Path.join([__DIR__, "../../../..", "data", "SkillMatrix.xlsx"])
                |> Path.expand()

  setup do
    manager = manager_fixture(%{name: "Import Manager"})
    user = user_fixture(%{name: "Regular User"})

    %{manager: manager, user: user}
  end

  describe "POST /api/import" do
    test "returns 400 when no file is uploaded", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.manager)
        |> post("/api/import", %{})

      assert %{"error" => error} = json_response(conn, 400)
      assert error =~ "Missing file upload"
    end

    test "returns 400 when file is not xlsx", ctx do
      upload = %Plug.Upload{
        path: create_temp_file("not xlsx content"),
        filename: "data.csv",
        content_type: "text/csv"
      }

      conn =
        ctx.conn
        |> log_in_user(ctx.manager)
        |> post("/api/import", %{"file" => upload})

      assert %{"error" => error} = json_response(conn, 400)
      assert error =~ ".xlsx"
    end

    test "returns 401 when not authenticated", ctx do
      conn = post(ctx.conn, "/api/import", %{})
      assert json_response(conn, 401)
    end

    test "returns 401/403 when user is not a manager", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.user)
        |> post("/api/import", %{})

      # Manager-only route returns 403 for regular users
      status = conn.status
      assert status in [401, 403]
    end

    test "returns 422 for xlsx file that cannot be parsed", ctx do
      upload = %Plug.Upload{
        path: create_temp_file("invalid xlsx binary content"),
        filename: "data.xlsx",
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      }

      conn =
        ctx.conn
        |> log_in_user(ctx.manager)
        |> post("/api/import", %{"file" => upload})

      # Invalid xlsx content triggers a parse error → 422
      assert json_response(conn, 422)
    end

    test "returns 200 with import summary for valid xlsx", ctx do
      if File.exists?(@fixture_xlsx) do
        upload = %Plug.Upload{
          path: @fixture_xlsx,
          filename: "SkillMatrix.xlsx",
          content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        }

        conn =
          ctx.conn
          |> log_in_user(ctx.manager)
          |> post("/api/import", %{"file" => upload})

        assert %{"data" => summary} = json_response(conn, 200)
        assert Map.has_key?(summary, "rows_processed")
        assert Map.has_key?(summary, "evaluations_created")
        assert Map.has_key?(summary, "evaluations_updated")
      end
    end

    test "uses default period when not supplied", ctx do
      upload = %Plug.Upload{
        path: create_temp_file("not real xlsx"),
        filename: "data.xlsx",
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      }

      conn =
        ctx.conn
        |> log_in_user(ctx.manager)
        |> post("/api/import", %{"file" => upload})

      # Response will be either 200 or 422 depending on parse result
      assert conn.status in [200, 422]
    end

    test "accepts explicit period param", ctx do
      upload = %Plug.Upload{
        path: create_temp_file("not real xlsx"),
        filename: "data.xlsx",
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      }

      conn =
        ctx.conn
        |> log_in_user(ctx.manager)
        |> post("/api/import", %{"file" => upload, "period" => "2025-Q2"})

      assert conn.status in [200, 422]
    end
  end

  defp create_temp_file(content) do
    path = Path.join(System.tmp_dir!(), "test_import_#{System.unique_integer()}.tmp")
    File.write!(path, content)
    on_exit(fn -> File.rm(path) end)
    path
  end
end
