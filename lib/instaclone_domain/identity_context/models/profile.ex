defmodule InstacloneDomain.IdentityContext.Models.Profile do
  @type profile :: %{
          id: String.t(),
          user: User.user(),
          handle: String.t(),
          follows: list(profile()) | :break,
          followers: list(profile()) | :break
        }
end
