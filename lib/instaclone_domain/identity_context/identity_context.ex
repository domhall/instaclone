defmodule InstacloneDomain.IdentityContext do
  @user_repository Application.compile_env(:instaclone, :identity_domain)[:ports][
                     :user_repository
                   ]

  @spec register_user(email :: String.t()) :: Models.user()
  def register_user(email) do
    {:ok, user} = @user_repository.create_user(email)
    user
  end

  @spec get_user(id :: String.t()) :: Models.user()
  def get_user(id) do
    @user_repository.get_user_by_id(id)
  end
end
