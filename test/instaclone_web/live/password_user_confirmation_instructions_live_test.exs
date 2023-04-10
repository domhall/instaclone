defmodule InstacloneWeb.PasswordUserConfirmationInstructionsLiveTest do
  use InstacloneWeb.ConnCase

  import Phoenix.LiveViewTest
  import Instaclone.IdentityFixtures

  alias Instaclone.Identity
  alias Instaclone.Repo

  setup do
    %{password_user: password_user_fixture()}
  end

  describe "Resend confirmation" do
    test "renders the resend confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/password_users/confirm")
      assert html =~ "Resend confirmation instructions"
    end

    test "sends a new confirmation token", %{conn: conn, password_user: password_user} do
      {:ok, lv, _html} = live(conn, ~p"/password_users/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", password_user: %{email: password_user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Identity.PasswordUserToken, password_user_id: password_user.id).context == "confirm"
    end

    test "does not send confirmation token if password_user is confirmed", %{conn: conn, password_user: password_user} do
      Repo.update!(Identity.PasswordUser.confirm_changeset(password_user))

      {:ok, lv, _html} = live(conn, ~p"/password_users/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", password_user: %{email: password_user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      refute Repo.get_by(Identity.PasswordUserToken, password_user_id: password_user.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/password_users/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", password_user: %{email: "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Identity.PasswordUserToken) == []
    end
  end
end
