defmodule Instaclone.Repo.Migrations.AssociatePasswordUserWithUser do
  use Ecto.Migration

  def change do
    alter table(:password_users) do
      add :user_id, :binary_id
    end
  end
end
