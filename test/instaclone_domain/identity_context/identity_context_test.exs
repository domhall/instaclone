defmodule InstacloneDomain.IdentityContext.IdentityContextTest do
  use ExUnit.Case

  describe "Register a new user" do
    test "Can register a new user" do
      user = InstacloneDomain.IdentityContext.register_user("test.email@example.com")
      assert user.email == "test.email@example.com"
    end
  end
end
