defmodule InstacloneWeb.PasswordUserConfirmationLiveTest do
  use InstacloneWeb.ConnCase

  import Phoenix.LiveViewTest
  import Instaclone.IdentityFixtures

  alias Instaclone.Identity
  alias Instaclone.Repo

  setup do
    %{password_user: password_user_fixture()}
  end

  describe "Confirm password_user" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/password_users/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, password_user: password_user} do
      token =
        extract_password_user_token(fn url ->
          Identity.deliver_password_user_confirmation_instructions(password_user, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/password_users/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "PasswordUser confirmed successfully"

      assert Identity.get_password_user!(password_user.id).confirmed_at
      refute get_session(conn, :password_user_token)
      assert Repo.all(Identity.PasswordUserToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/password_users/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "PasswordUser confirmation link is invalid or it has expired"

      # when logged in
      {:ok, lv, _html} =
        build_conn()
        |> log_in_password_user(password_user)
        |> live(~p"/password_users/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, password_user: password_user} do
      {:ok, lv, _html} = live(conn, ~p"/password_users/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "PasswordUser confirmation link is invalid or it has expired"

      refute Identity.get_password_user!(password_user.id).confirmed_at
    end
  end
end
