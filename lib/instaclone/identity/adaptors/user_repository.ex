defmodule Instaclone.Identity.Adaptors.UserRepository do
  @behaviour InstacloneDomain.IdentityContext.Ports.UserRepository
  @impl true
  def get_user_by_id(id) do
    user =
      Instaclone.Repo.get(:user, id)
      |> map_user_dao_to_user()

    {:ok, user}
  end

  @impl true
  def create_user(email) do
    user =
      Instaclone.Repo.insert!(%Instaclone.Identity.User{email: email})
      |> map_user_dao_to_user()

    {:ok, user}
  end

  defp map_user_dao_to_user(user_dao) do
    %{id: user_dao.id, email: user_dao.email}
  end
end
