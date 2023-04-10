defmodule Instaclone.Repo.Migrations.CreatePasswordUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:password_users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:password_users, [:email])

    create table(:password_users_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :password_user_id, references(:password_users, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:password_users_tokens, [:password_user_id])
    create unique_index(:password_users_tokens, [:context, :token])
  end
end
