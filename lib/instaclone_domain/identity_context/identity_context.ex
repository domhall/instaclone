defmodule InstacloneDomain.IdentityContext do
  @user_repository Application.compile_env(
                     :instaclone,
                     [
                       :identity_domain,
                       :ports,
                       :user_repository
                     ],
                     InstacloneDomain.IdentityContext.Adaptors.StubUserRepository
                   )

  @spec get_user(id :: String.t()) :: Models.User.user()
  def get_user(id) do
    {:ok, user} = @user_repository.get_user_by_id(id)
    user
  end

  @spec register_user(email :: String.t()) :: Models.User.user()
  def register_user(email) do
    {:ok, user} = @user_repository.create_user(email)
    user
  end

  @spec create_profile(user_id :: String.t(), handle :: String.t()) :: Models.profile()
  def create_profile(user_id, handle) do
    user = get_user(user_id)
    %{profiles: profiles} = user

    user =
      Map.put(user, :profiles, [
        %{
          handle: handle,
          user: user
        }
        | profiles
      ])

    %{profiles: profiles} = @user_repository.update_user(user)
    Enum.find(profiles, fn profile -> profile.handle == handle end)
  end
end
