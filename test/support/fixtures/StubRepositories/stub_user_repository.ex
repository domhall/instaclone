defmodule InstacloneDomain.IdentityContext.Adaptors.StubUserRepository do
  @behaviour InstacloneDomain.IdentityContext.Ports.UserRepository

  @impl true
  def get_user_by_id(id) do
    {:ok, %{id: id, email: "fake@example.com", profiles: []}}
  end

  @impl true
  def create_user(email) do
    {:ok, %{id: Ecto.UUID.generate(), email: email, profiles: []}}
  end

  @impl true
  def update_user(user) do
    user
  end
end
