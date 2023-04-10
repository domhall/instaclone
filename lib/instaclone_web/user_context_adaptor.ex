defmodule InstacloneWeb.UserContextAdaptor do
  use InstacloneWeb, :verified_routes

  import Plug.Conn

  alias InstacloneDomain.IdentityContext

  @doc """
  Authenticates the password_user by looking into the session
  and remember me token.
  """
  def fetch_current_user(conn, user_id) do
    current_user = IdentityContext.get_user(user_id)
    assign(conn, :current_user, current_user)
  end
end
