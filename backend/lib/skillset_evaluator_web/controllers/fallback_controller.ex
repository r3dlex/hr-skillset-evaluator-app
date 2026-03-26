defmodule SkillsetEvaluatorWeb.FallbackController do
  use SkillsetEvaluatorWeb, :controller

  def index(conn, _params) do
    index_path = Application.app_dir(:skillset_evaluator, "priv/static/index.html")

    if File.exists?(index_path) do
      conn
      |> put_resp_content_type("text/html")
      |> send_file(200, index_path)
    else
      conn
      |> put_status(:not_found)
      |> json(%{error: "Not found"})
    end
  end
end
