defmodule InstacloneDomain.IdentityContext.Ports.UserRepository do
  @callback create_user(email :: String.t()) ::
              {:ok, user :: Models.user()} | {:error, reason :: term}
  @callback get_user_by_id(id :: String.t()) ::
              {:ok, user :: Models.user()} | {:error, reason :: term}
end
