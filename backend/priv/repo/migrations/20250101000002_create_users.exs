defmodule SkillsetEvaluator.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :hashed_password, :string
      add :role, :string, default: "user", null: false
      add :name, :string
      add :location, :string
      add :microsoft_uid, :string
      add :active, :boolean, default: true, null: false
      add :confirmed_at, :utc_datetime
      add :team_id, references(:teams, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create index(:users, [:team_id])
    create index(:users, [:microsoft_uid])
  end
end
