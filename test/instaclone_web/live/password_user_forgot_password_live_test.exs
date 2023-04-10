defmodule InstacloneWeb.PasswordUserForgotPasswordLiveTest do
  use InstacloneWeb.ConnCase

  import Phoenix.LiveViewTest
  import Instaclone.IdentityFixtures

  alias Instaclone.Identity
  alias Instaclone.Repo

  describe "Forgot password page" do
    test "renders email page", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/password_users/reset_password")

      assert html =~ "Forgot your password?"
      assert has_element?(lv, ~s|a[href="#{~p"/password_users/register"}"]|, "Register")
      assert has_element?(lv, ~s|a[href="#{~p"/password_users/log_in"}"]|, "Log in")
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_password_user(password_user_fixture())
        |> live(~p"/password_users/reset_password")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end
  end

  describe "Reset link" do
    setup do
      %{password_user: password_user_fixture()}
    end

    test "sends a new reset password token", %{conn: conn, password_user: password_user} do
      {:ok, lv, _html} = live(conn, ~p"/password_users/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", password_user: %{"email" => password_user.email})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"

      assert Repo.get_by!(Identity.PasswordUserToken, password_user_id: password_user.id).context ==
               "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/password_users/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", password_user: %{"email" => "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert Repo.all(Identity.PasswordUserToken) == []
    end
  end
end
