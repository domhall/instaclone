defmodule Instaclone.Identity.Adaptors.UserRepositoryTest do
  use Instaclone.DataCase
  use ExUnit.Case

  alias Instaclone.Identity.Adaptors.UserRepository

  describe "Can create and get users" do
    test "can create a user" do
      {:ok, user} = UserRepository.create_user("a-fresh-email@example.com")

      assert user.email == "a-fresh-email@example.com"
    end

    test "can get a user" do
      {:ok, %{id: id}} = UserRepository.create_user("a-fresh-email-2@example.com")

      {:ok, user} = UserRepository.get_user_by_id(id)

      assert user.email == "a-fresh-email-2@example.com"
      assert user.id == id
    end

    test "can update a user's email" do
      {:ok, created_user} = UserRepository.create_user("a-pre-updated-email@example.com")

      pre_updated_user = Map.put(created_user, :email, "an-updated-email@example.com")
      {:ok, updated_user} = UserRepository.update_user(pre_updated_user)

      assert updated_user.email == "an-updated-email@example.com"
      assert updated_user.id == created_user.id
    end

    test "can add a profile to a user" do
      {:ok, created_user} = UserRepository.create_user("a-profile-test-email@example.com")

      pre_updated_user =
        Map.put(created_user, :profiles, [
          %{
            user: created_user,
            handle: "dom"
          }
        ])

      {:ok, updated_user} = UserRepository.update_user(pre_updated_user)

      [saved_profile | _] = updated_user.profiles

      assert saved_profile.handle == "dom"
    end
  end
end
