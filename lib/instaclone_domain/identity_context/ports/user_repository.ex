defmodule InstacloneDomain.IdentityContext.Ports.UserRepository do
  @callback create_user(email :: String.t()) ::
              {:ok, user :: Models.User.user()}
  @callback get_user_by_id(id :: String.t()) ::
              {:ok, user :: Models.User.user()}
  @callback update_user(user :: Models.User.user()) ::
              {:ok, user :: Models.User.user()}
end
