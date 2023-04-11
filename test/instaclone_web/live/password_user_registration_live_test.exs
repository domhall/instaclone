defmodule InstacloneWeb.PasswordUserRegistrationLiveTest do
  use InstacloneWeb.ConnCase

  import Phoenix.LiveViewTest
  import Instaclone.IdentityFixtures

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/password_users/register")

      assert html =~ "Register"
      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_password_user(password_user_fixture())
        |> live(~p"/password_users/register")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/password_users/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(password_user: %{"email" => "with spaces", "password" => "too short"})

      assert result =~ "Register"
      assert result =~ "must have the @ sign and no spaces"
      assert result =~ "should be at least 12 character"
    end
  end

  describe "register password_user" do
    test "creates account and logs the password_user in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/password_users/register")

      email = unique_password_user_email()

      form =
        form(lv, "#registration_form",
          password_user: valid_password_user_form_attributes(email: email)
        )

      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ "fake@example.com"
      assert response =~ "Settings"
      assert response =~ "Log out"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/password_users/register")

      password_user = password_user_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          password_user: %{"email" => password_user.email, "password" => "valid_password"}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/password_users/register")

      {:ok, _login_live, login_html} =
        lv
        |> element(~s|main a:fl-contains("Sign in")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/password_users/log_in")

      assert login_html =~ "Log in"
    end
  end
end
