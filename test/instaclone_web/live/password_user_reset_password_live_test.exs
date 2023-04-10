defmodule InstacloneWeb.PasswordUserResetPasswordLiveTest do
  use InstacloneWeb.ConnCase

  import Phoenix.LiveViewTest
  import Instaclone.IdentityFixtures

  alias Instaclone.Identity

  setup do
    password_user = password_user_fixture()

    token =
      extract_password_user_token(fn url ->
        Identity.deliver_password_user_reset_password_instructions(password_user, url)
      end)

    %{token: token, password_user: password_user}
  end

  describe "Reset password page" do
    test "renders reset password with valid token", %{conn: conn, token: token} do
      {:ok, _lv, html} = live(conn, ~p"/password_users/reset_password/#{token}")

      assert html =~ "Reset Password"
    end

    test "does not render reset password with invalid token", %{conn: conn} do
      {:error, {:redirect, to}} = live(conn, ~p"/password_users/reset_password/invalid")

      assert to == %{
               flash: %{"error" => "Reset password link is invalid or it has expired."},
               to: ~p"/"
             }
    end

    test "renders errors for invalid data", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/password_users/reset_password/#{token}")

      result =
        lv
        |> element("#reset_password_form")
        |> render_change(
          password_user: %{"password" => "secret12", "confirmation_password" => "secret123456"}
        )

      assert result =~ "should be at least 12 character"
      assert result =~ "does not match password"
    end
  end

  describe "Reset Password" do
    test "resets password once", %{conn: conn, token: token, password_user: password_user} do
      {:ok, lv, _html} = live(conn, ~p"/password_users/reset_password/#{token}")

      {:ok, conn} =
        lv
        |> form("#reset_password_form",
          password_user: %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        )
        |> render_submit()
        |> follow_redirect(conn, ~p"/password_users/log_in")

      refute get_session(conn, :password_user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password reset successfully"
      assert Identity.get_password_user_by_email_and_password(password_user.email, "new valid password")
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/password_users/reset_password/#{token}")

      result =
        lv
        |> form("#reset_password_form",
          password_user: %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        )
        |> render_submit()

      assert result =~ "Reset Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end
  end

  describe "Reset password navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/password_users/reset_password/#{token}")

      {:ok, conn} =
        lv
        |> element(~s|main a:fl-contains("Log in")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/password_users/log_in")

      assert conn.resp_body =~ "Log in"
    end

    test "redirects to password reset page when the Register button is clicked", %{
      conn: conn,
      token: token
    } do
      {:ok, lv, _html} = live(conn, ~p"/password_users/reset_password/#{token}")

      {:ok, conn} =
        lv
        |> element(~s|main a:fl-contains("Register")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/password_users/register")

      assert conn.resp_body =~ "Register"
    end
  end
end
