defmodule InstacloneDomain.IdentityContext.Models.User do
  alias InstacloneDomain.IdentityContext.Models
  @type user :: %{id: String.t(), email: String.t(), profiles: list(Models.Profile.profile())}
end
