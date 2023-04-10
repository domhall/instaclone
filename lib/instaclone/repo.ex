defmodule Instaclone.Repo do
  use Ecto.Repo,
    otp_app: :instaclone,
    adapter: Ecto.Adapters.Postgres
end
