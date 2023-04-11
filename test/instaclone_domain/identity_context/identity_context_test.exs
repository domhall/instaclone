defmodule InstacloneDomain.IdentityContext.IdentityContextTest do
  use ExUnit.Case

  describe "Register a new user" do
    test "Can register a new user" do
      user = InstacloneDomain.IdentityContext.register_user("test.email@example.com")
      assert user.email == "test.email@example.com"
    end
  end

  describe "Get an existing user" do
    test "Can get an existing user" do
      user = InstacloneDomain.IdentityContext.get_user("test-uuid")
      assert user.id == "test-uuid"
      assert user.email == "fake@example.com"
    end
  end

  describe "Update an existing user" do
    test "Can add a profile to a user" do
      profile = InstacloneDomain.IdentityContext.create_profile("test-uuid", "dom")
      assert profile.handle == "dom"
      assert profile.user.email == "fake@example.com"
    end
  end
end
