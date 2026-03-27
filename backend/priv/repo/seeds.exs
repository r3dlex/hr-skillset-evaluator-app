alias SkillsetEvaluator.Repo
alias SkillsetEvaluator.Accounts.User

admin_email = System.get_env("ADMIN_EMAIL") || "admin@example.com"
admin_password = System.get_env("ADMIN_PASSWORD") || "admin123456"

# 1. Create or update admin user
admin =
  case Repo.get_by(User, email: admin_email) do
    nil ->
      {:ok, user} =
        %User{}
        |> User.registration_changeset(%{
          email: admin_email,
          password: admin_password,
          name: "Admin",
          role: "admin",
          confirmed_at: DateTime.utc_now()
        })
        |> Repo.insert()

      IO.puts("Default admin user created: #{admin_email}")
      user

    user ->
      # Ensure admin role is set (may have been seeded as manager previously)
      if user.role != "admin" do
        user
        |> Ecto.Changeset.change(%{role: "admin"})
        |> Repo.update!()

        IO.puts("Updated #{admin_email} role to admin")
      else
        IO.puts("Admin user already exists: #{admin_email}")
      end

      user
  end

# 2. Auto-import xlsx if present and no skillsets exist yet
xlsx_path = "/app/data/SkillMatrix.xlsx"

if File.exists?(xlsx_path) do
  skillset_count = Repo.aggregate(SkillsetEvaluator.Skills.Skillset, :count, :id)

  if skillset_count < 3 do
    IO.puts("Importing xlsx from #{xlsx_path}...")

    case SkillsetEvaluator.Import.Pipeline.run_import(xlsx_path, "2025-Q1", admin.id) do
      {:ok, summary} ->
        IO.puts(
          "Import complete: #{summary.rows_processed} rows, #{summary.evaluations_created} created, #{summary.evaluations_updated} updated"
        )

      {:error, reason} ->
        IO.puts("Import failed: #{reason}")
    end
  else
    IO.puts("Skillsets already populated (#{skillset_count}), skipping xlsx import")
  end
else
  IO.puts("No xlsx found at #{xlsx_path}, skipping import")
end

# 3. Seed glossary terms (non-fatal if file not found in release)
glossary_paths = [
  Path.join(:code.priv_dir(:skillset_evaluator), "repo/seeds_glossary.exs"),
  "priv/repo/seeds_glossary.exs"
]

case Enum.find(glossary_paths, &File.exists?/1) do
  nil ->
    IO.puts("Glossary seed file not found, skipping")

  path ->
    IO.puts("Seeding glossary from #{path}")
    Code.eval_file(path)
end
