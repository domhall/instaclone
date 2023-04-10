defmodule InstacloneDomain.IdentityContext do
  @user_repository Application.compile_env(:instaclone, [
                     :identity_domain,
                     :ports,
                     :user_repository
                   ])
  @spec register_user({email :: String.t()}) :: %{email: String.t(), id: String.t()}
  def register_user(email) do
    @user_repository.create_user(email)
  end

  @spec get_user({id :: String.t()}) :: %{email: String.t(), id: String.t()}
  def get_user(id) do
    @user_repository.get_user_by_id(id)
  end
end
