alias SkillsetEvaluator.Repo
alias SkillsetEvaluator.Accounts.User

admin_email = System.get_env("ADMIN_EMAIL") || "admin@example.com"
admin_password = System.get_env("ADMIN_PASSWORD") || "admin123456"

case Repo.get_by(User, email: admin_email) do
  nil ->
    %User{}
    |> User.registration_changeset(%{
      email: admin_email,
      password: admin_password,
      name: "Admin",
      role: "manager",
      confirmed_at: DateTime.utc_now()
    })
    |> Repo.insert!()

    IO.puts("Default admin user created: #{admin_email}")

  _user ->
    IO.puts("Admin user already exists: #{admin_email}")
end
