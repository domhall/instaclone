defmodule Instaclone.IdentityTest do
  use Instaclone.DataCase

  alias Instaclone.Identity

  import Instaclone.IdentityFixtures
  alias Instaclone.Identity.{PasswordUser, PasswordUserToken}

  describe "get_password_user_by_email/1" do
    test "does not return the password_user if the email does not exist" do
      refute Identity.get_password_user_by_email("unknown@example.com")
    end

    test "returns the password_user if the email exists" do
      %{id: id} = password_user = password_user_fixture()
      assert %PasswordUser{id: ^id} = Identity.get_password_user_by_email(password_user.email)
    end
  end

  describe "get_password_user_by_email_and_password/2" do
    test "does not return the password_user if the email does not exist" do
      refute Identity.get_password_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the password_user if the password is not valid" do
      password_user = password_user_fixture()
      refute Identity.get_password_user_by_email_and_password(password_user.email, "invalid")
    end

    test "returns the password_user if the email and password are valid" do
      %{id: id} = password_user = password_user_fixture()

      assert %PasswordUser{id: ^id} =
               Identity.get_password_user_by_email_and_password(password_user.email, valid_password_user_password())
    end
  end

  describe "get_password_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Identity.get_password_user!("11111111-1111-1111-1111-111111111111")
      end
    end

    test "returns the password_user with the given id" do
      %{id: id} = password_user = password_user_fixture()
      assert %PasswordUser{id: ^id} = Identity.get_password_user!(password_user.id)
    end
  end

  describe "register_password_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Identity.register_password_user(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Identity.register_password_user(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Identity.register_password_user(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = password_user_fixture()
      {:error, changeset} = Identity.register_password_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Identity.register_password_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers password_users with a hashed password" do
      email = unique_password_user_email()
      {:ok, password_user} = Identity.register_password_user(valid_password_user_attributes(email: email))
      assert password_user.email == email
      assert is_binary(password_user.hashed_password)
      assert is_nil(password_user.confirmed_at)
      assert is_nil(password_user.password)
    end
  end

  describe "change_password_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Identity.change_password_user_registration(%PasswordUser{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_password_user_email()
      password = valid_password_user_password()

      changeset =
        Identity.change_password_user_registration(
          %PasswordUser{},
          valid_password_user_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_password_user_email/2" do
    test "returns a password_user changeset" do
      assert %Ecto.Changeset{} = changeset = Identity.change_password_user_email(%PasswordUser{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_password_user_email/3" do
    setup do
      %{password_user: password_user_fixture()}
    end

    test "requires email to change", %{password_user: password_user} do
      {:error, changeset} = Identity.apply_password_user_email(password_user, valid_password_user_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{password_user: password_user} do
      {:error, changeset} =
        Identity.apply_password_user_email(password_user, valid_password_user_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{password_user: password_user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Identity.apply_password_user_email(password_user, valid_password_user_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{password_user: password_user} do
      %{email: email} = password_user_fixture()
      password = valid_password_user_password()

      {:error, changeset} = Identity.apply_password_user_email(password_user, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{password_user: password_user} do
      {:error, changeset} =
        Identity.apply_password_user_email(password_user, "invalid", %{email: unique_password_user_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{password_user: password_user} do
      email = unique_password_user_email()
      {:ok, password_user} = Identity.apply_password_user_email(password_user, valid_password_user_password(), %{email: email})
      assert password_user.email == email
      assert Identity.get_password_user!(password_user.id).email != email
    end
  end

  describe "deliver_password_user_update_email_instructions/3" do
    setup do
      %{password_user: password_user_fixture()}
    end

    test "sends token through notification", %{password_user: password_user} do
      token =
        extract_password_user_token(fn url ->
          Identity.deliver_password_user_update_email_instructions(password_user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert password_user_token = Repo.get_by(PasswordUserToken, token: :crypto.hash(:sha256, token))
      assert password_user_token.password_user_id == password_user.id
      assert password_user_token.sent_to == password_user.email
      assert password_user_token.context == "change:current@example.com"
    end
  end

  describe "update_password_user_email/2" do
    setup do
      password_user = password_user_fixture()
      email = unique_password_user_email()

      token =
        extract_password_user_token(fn url ->
          Identity.deliver_password_user_update_email_instructions(%{password_user | email: email}, password_user.email, url)
        end)

      %{password_user: password_user, token: token, email: email}
    end

    test "updates the email with a valid token", %{password_user: password_user, token: token, email: email} do
      assert Identity.update_password_user_email(password_user, token) == :ok
      changed_password_user = Repo.get!(PasswordUser, password_user.id)
      assert changed_password_user.email != password_user.email
      assert changed_password_user.email == email
      assert changed_password_user.confirmed_at
      assert changed_password_user.confirmed_at != password_user.confirmed_at
      refute Repo.get_by(PasswordUserToken, password_user_id: password_user.id)
    end

    test "does not update email with invalid token", %{password_user: password_user} do
      assert Identity.update_password_user_email(password_user, "oops") == :error
      assert Repo.get!(PasswordUser, password_user.id).email == password_user.email
      assert Repo.get_by(PasswordUserToken, password_user_id: password_user.id)
    end

    test "does not update email if password_user email changed", %{password_user: password_user, token: token} do
      assert Identity.update_password_user_email(%{password_user | email: "current@example.com"}, token) == :error
      assert Repo.get!(PasswordUser, password_user.id).email == password_user.email
      assert Repo.get_by(PasswordUserToken, password_user_id: password_user.id)
    end

    test "does not update email if token expired", %{password_user: password_user, token: token} do
      {1, nil} = Repo.update_all(PasswordUserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Identity.update_password_user_email(password_user, token) == :error
      assert Repo.get!(PasswordUser, password_user.id).email == password_user.email
      assert Repo.get_by(PasswordUserToken, password_user_id: password_user.id)
    end
  end

  describe "change_password_user_password/2" do
    test "returns a password_user changeset" do
      assert %Ecto.Changeset{} = changeset = Identity.change_password_user_password(%PasswordUser{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Identity.change_password_user_password(%PasswordUser{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_password_user_password/3" do
    setup do
      %{password_user: password_user_fixture()}
    end

    test "validates password", %{password_user: password_user} do
      {:error, changeset} =
        Identity.update_password_user_password(password_user, valid_password_user_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{password_user: password_user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Identity.update_password_user_password(password_user, valid_password_user_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{password_user: password_user} do
      {:error, changeset} =
        Identity.update_password_user_password(password_user, "invalid", %{password: valid_password_user_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{password_user: password_user} do
      {:ok, password_user} =
        Identity.update_password_user_password(password_user, valid_password_user_password(), %{
          password: "new valid password"
        })

      assert is_nil(password_user.password)
      assert Identity.get_password_user_by_email_and_password(password_user.email, "new valid password")
    end

    test "deletes all tokens for the given password_user", %{password_user: password_user} do
      _ = Identity.generate_password_user_session_token(password_user)

      {:ok, _} =
        Identity.update_password_user_password(password_user, valid_password_user_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(PasswordUserToken, password_user_id: password_user.id)
    end
  end

  describe "generate_password_user_session_token/1" do
    setup do
      %{password_user: password_user_fixture()}
    end

    test "generates a token", %{password_user: password_user} do
      token = Identity.generate_password_user_session_token(password_user)
      assert password_user_token = Repo.get_by(PasswordUserToken, token: token)
      assert password_user_token.context == "session"

      # Creating the same token for another password_user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%PasswordUserToken{
          token: password_user_token.token,
          password_user_id: password_user_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_password_user_by_session_token/1" do
    setup do
      password_user = password_user_fixture()
      token = Identity.generate_password_user_session_token(password_user)
      %{password_user: password_user, token: token}
    end

    test "returns password_user by token", %{password_user: password_user, token: token} do
      assert session_password_user = Identity.get_password_user_by_session_token(token)
      assert session_password_user.id == password_user.id
    end

    test "does not return password_user for invalid token" do
      refute Identity.get_password_user_by_session_token("oops")
    end

    test "does not return password_user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(PasswordUserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Identity.get_password_user_by_session_token(token)
    end
  end

  describe "delete_password_user_session_token/1" do
    test "deletes the token" do
      password_user = password_user_fixture()
      token = Identity.generate_password_user_session_token(password_user)
      assert Identity.delete_password_user_session_token(token) == :ok
      refute Identity.get_password_user_by_session_token(token)
    end
  end

  describe "deliver_password_user_confirmation_instructions/2" do
    setup do
      %{password_user: password_user_fixture()}
    end

    test "sends token through notification", %{password_user: password_user} do
      token =
        extract_password_user_token(fn url ->
          Identity.deliver_password_user_confirmation_instructions(password_user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert password_user_token = Repo.get_by(PasswordUserToken, token: :crypto.hash(:sha256, token))
      assert password_user_token.password_user_id == password_user.id
      assert password_user_token.sent_to == password_user.email
      assert password_user_token.context == "confirm"
    end
  end

  describe "confirm_password_user/1" do
    setup do
      password_user = password_user_fixture()

      token =
        extract_password_user_token(fn url ->
          Identity.deliver_password_user_confirmation_instructions(password_user, url)
        end)

      %{password_user: password_user, token: token}
    end

    test "confirms the email with a valid token", %{password_user: password_user, token: token} do
      assert {:ok, confirmed_password_user} = Identity.confirm_password_user(token)
      assert confirmed_password_user.confirmed_at
      assert confirmed_password_user.confirmed_at != password_user.confirmed_at
      assert Repo.get!(PasswordUser, password_user.id).confirmed_at
      refute Repo.get_by(PasswordUserToken, password_user_id: password_user.id)
    end

    test "does not confirm with invalid token", %{password_user: password_user} do
      assert Identity.confirm_password_user("oops") == :error
      refute Repo.get!(PasswordUser, password_user.id).confirmed_at
      assert Repo.get_by(PasswordUserToken, password_user_id: password_user.id)
    end

    test "does not confirm email if token expired", %{password_user: password_user, token: token} do
      {1, nil} = Repo.update_all(PasswordUserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Identity.confirm_password_user(token) == :error
      refute Repo.get!(PasswordUser, password_user.id).confirmed_at
      assert Repo.get_by(PasswordUserToken, password_user_id: password_user.id)
    end
  end

  describe "deliver_password_user_reset_password_instructions/2" do
    setup do
      %{password_user: password_user_fixture()}
    end

    test "sends token through notification", %{password_user: password_user} do
      token =
        extract_password_user_token(fn url ->
          Identity.deliver_password_user_reset_password_instructions(password_user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert password_user_token = Repo.get_by(PasswordUserToken, token: :crypto.hash(:sha256, token))
      assert password_user_token.password_user_id == password_user.id
      assert password_user_token.sent_to == password_user.email
      assert password_user_token.context == "reset_password"
    end
  end

  describe "get_password_user_by_reset_password_token/1" do
    setup do
      password_user = password_user_fixture()

      token =
        extract_password_user_token(fn url ->
          Identity.deliver_password_user_reset_password_instructions(password_user, url)
        end)

      %{password_user: password_user, token: token}
    end

    test "returns the password_user with valid token", %{password_user: %{id: id}, token: token} do
      assert %PasswordUser{id: ^id} = Identity.get_password_user_by_reset_password_token(token)
      assert Repo.get_by(PasswordUserToken, password_user_id: id)
    end

    test "does not return the password_user with invalid token", %{password_user: password_user} do
      refute Identity.get_password_user_by_reset_password_token("oops")
      assert Repo.get_by(PasswordUserToken, password_user_id: password_user.id)
    end

    test "does not return the password_user if token expired", %{password_user: password_user, token: token} do
      {1, nil} = Repo.update_all(PasswordUserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Identity.get_password_user_by_reset_password_token(token)
      assert Repo.get_by(PasswordUserToken, password_user_id: password_user.id)
    end
  end

  describe "reset_password_user_password/2" do
    setup do
      %{password_user: password_user_fixture()}
    end

    test "validates password", %{password_user: password_user} do
      {:error, changeset} =
        Identity.reset_password_user_password(password_user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{password_user: password_user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Identity.reset_password_user_password(password_user, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{password_user: password_user} do
      {:ok, updated_password_user} = Identity.reset_password_user_password(password_user, %{password: "new valid password"})
      assert is_nil(updated_password_user.password)
      assert Identity.get_password_user_by_email_and_password(password_user.email, "new valid password")
    end

    test "deletes all tokens for the given password_user", %{password_user: password_user} do
      _ = Identity.generate_password_user_session_token(password_user)
      {:ok, _} = Identity.reset_password_user_password(password_user, %{password: "new valid password"})
      refute Repo.get_by(PasswordUserToken, password_user_id: password_user.id)
    end
  end

  describe "inspect/2 for the PasswordUser module" do
    test "does not include password" do
      refute inspect(%PasswordUser{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
