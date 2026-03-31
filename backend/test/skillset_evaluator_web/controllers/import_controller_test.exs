defmodule SkillsetEvaluatorWeb.ImportControllerTest do
  use SkillsetEvaluatorWeb.ConnCase

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
  end

  defp create_temp_file(content) do
    path = Path.join(System.tmp_dir!(), "test_import_#{System.unique_integer()}.tmp")
    File.write!(path, content)
    on_exit(fn -> File.rm(path) end)
    path
  end
end
