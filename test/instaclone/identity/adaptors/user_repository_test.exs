defmodule Instaclone.Identity.Adaptors.UserRepositoryTest do
  use Instaclone.DataCase
  use ExUnit.Case

  alias Instaclone.Identity.Adaptors.UserRepository

  describe "Can create and get users" do
    test "can create a user" do
      {:ok, user} = UserRepository.create_user("a-fresh-email@example.com")
      assert user.email == "a-fresh-email@example.com"
    end

    test "can get user" do
      {:ok, %{id: id}} = UserRepository.create_user("a-fresh-email-2@example.com")
      {:ok, user} = UserRepository.get_user_by_id(id)
      assert user.email == "a-fresh-email-2@example.com"
      assert user.id == id
    end
  end
end
