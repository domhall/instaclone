defmodule Instaclone.Identity.Adaptors.UserRepository do
  alias Instaclone.Identity.User, as: UserRecord
  alias InstacloneDomain.IdentityContext.Models.User
  @behaviour InstacloneDomain.IdentityContext.Ports.UserRepository
  @impl true
  def get_user_by_id(id) do
    user =
      Instaclone.Repo.get(UserRecord, id)
      |> map_user_dao_to_user()

    {:ok, user}
  end

  @impl true
  def create_user(email) do
    user =
      Instaclone.Repo.insert!(%UserRecord{email: email})
      |> map_user_dao_to_user()

    {:ok, user}
  end

  @spec map_user_dao_to_user(UserRecord) :: User.user()
  defp map_user_dao_to_user(user_dao) do
    %{id: user_dao.id, email: user_dao.email}
  end
end
