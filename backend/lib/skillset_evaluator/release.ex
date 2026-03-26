defmodule SkillsetEvaluator.Release do
  @moduledoc """
  OTP release tasks (run without Mix available).
  Used in production for running migrations.
  """

  @app :skillset_evaluator

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def seed do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn _repo ->
          seed_file = Path.join([:code.priv_dir(@app), "repo", "seeds.exs"])

          if File.exists?(seed_file) do
            Code.eval_file(seed_file)
          end
        end)
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
    Application.ensure_all_started(:ecto)
  end
end
