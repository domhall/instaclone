defmodule InstacloneWeb.PasswordUserSettingsLiveTest do
  use InstacloneWeb.ConnCase

  alias Instaclone.Identity
  import Phoenix.LiveViewTest
  import Instaclone.IdentityFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_password_user(password_user_fixture())
        |> live(~p"/password_users/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if password_user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/password_users/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/password_users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_password_user_password()
      password_user = password_user_fixture(%{password: password})
      %{conn: log_in_password_user(conn, password_user), password_user: password_user, password: password}
    end

    test "updates the password_user email", %{conn: conn, password: password, password_user: password_user} do
      new_email = unique_password_user_email()

      {:ok, lv, _html} = live(conn, ~p"/password_users/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "password_user" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Identity.get_password_user_by_email(password_user.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/password_users/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "password_user" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, password_user: password_user} do
      {:ok, lv, _html} = live(conn, ~p"/password_users/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "password_user" => %{"email" => password_user.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_password_user_password()
      password_user = password_user_fixture(%{password: password})
      %{conn: log_in_password_user(conn, password_user), password_user: password_user, password: password}
    end

    test "updates the password_user password", %{conn: conn, password_user: password_user, password: password} do
      new_password = valid_password_user_password()

      {:ok, lv, _html} = live(conn, ~p"/password_users/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "password_user" => %{
            "email" => password_user.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/password_users/settings"

      assert get_session(new_password_conn, :password_user_token) != get_session(conn, :password_user_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Identity.get_password_user_by_email_and_password(password_user.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/password_users/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "password_user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/password_users/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "password_user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      password_user = password_user_fixture()
      email = unique_password_user_email()

      token =
        extract_password_user_token(fn url ->
          Identity.deliver_password_user_update_email_instructions(%{password_user | email: email}, password_user.email, url)
        end)

      %{conn: log_in_password_user(conn, password_user), token: token, email: email, password_user: password_user}
    end

    test "updates the password_user email once", %{conn: conn, password_user: password_user, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/password_users/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/password_users/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Identity.get_password_user_by_email(password_user.email)
      assert Identity.get_password_user_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/password_users/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/password_users/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, password_user: password_user} do
      {:error, redirect} = live(conn, ~p"/password_users/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/password_users/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Identity.get_password_user_by_email(password_user.email)
    end

    test "redirects if password_user is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/password_users/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/password_users/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
