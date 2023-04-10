defmodule InstacloneDomain.IdentityContext.Ports.StubUserRepository do
  @behaviour InstacloneDomain.IdentityContext.Ports.UserRepository

  @impl true
  def get_user_by_id(id) do
    {:ok, %{id: id, email: "fake@example.com"}}
  end

  @impl true
  def create_user(email) do
    {:ok, %{id: Ecto.UUID.generate(), email: email}}
  end
end
