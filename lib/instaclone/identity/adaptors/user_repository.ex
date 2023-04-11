defmodule Instaclone.Identity.Adaptors.UserRepository do
  alias Instaclone.Identity.User, as: UserRecord
  alias Instaclone.Identity.Profile, as: ProfileRecord
  alias InstacloneDomain.IdentityContext.Models.User
  @behaviour InstacloneDomain.IdentityContext.Ports.UserRepository
  @impl true
  def get_user_by_id(id) do
    user =
      Instaclone.Repo.get(UserRecord, id)
      |> Instaclone.Repo.preload([:profiles])
      |> map_user_dao_to_user()

    {:ok, user}
  end

  @impl true
  def create_user(email) do
    user =
      Instaclone.Repo.insert!(%UserRecord{email: email})
      |> Instaclone.Repo.preload([:profiles])
      |> map_user_dao_to_user()

    {:ok, user}
  end

  @impl true
  def update_user(user) do
    profiles = Enum.map(user.profiles, fn profile -> create_or_update_profile(profile) end)
    user = Map.put(user, :profiles, profiles)

    {:ok, updated_user} =
      Instaclone.Repo.get(UserRecord, user.id)
      |> Instaclone.Repo.preload([:profiles])
      |> Instaclone.Identity.User.changeset(user)
      |> Instaclone.Repo.update()

    updated_user = Instaclone.Repo.preload(updated_user, [:profiles])
    {:ok, map_user_dao_to_user(updated_user)}
  end

  defp create_or_update_profile(profile) do
    Instaclone.Repo.insert!(%ProfileRecord{handle: profile.handle, user_id: profile.user.id})
  end

  @spec map_user_dao_to_user(UserRecord) :: User.user()
  defp map_user_dao_to_user(user_dao) do
    %{
      id: user_dao.id,
      email: user_dao.email,
      profiles: Enum.map(user_dao.profiles, fn profile -> map_profile_dao_to_profile(profile) end)
    }
  end

  defp map_profile_dao_to_profile(profile) do
    %{id: profile.id, user: profile.user, handle: profile.handle, follows: [], followers: []}
  end
end
