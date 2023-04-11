defmodule InstacloneWeb.PasswordUserSessionControllerTest do
  use InstacloneWeb.ConnCase, async: true

  import Instaclone.IdentityFixtures

  setup do
    %{password_user: password_user_fixture()}
  end

  describe "POST /password_users/log_in" do
    test "logs the password_user in", %{conn: conn, password_user: password_user} do
      conn =
        post(conn, ~p"/password_users/log_in", %{
          "password_user" => %{
            "email" => password_user.email,
            "password" => valid_password_user_password()
          }
        })

      assert get_session(conn, :password_user_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ "fake@example.com"
      assert response =~ ~p"/password_users/settings"
      assert response =~ ~p"/password_users/log_out"
    end

    test "logs the password_user in with remember me", %{conn: conn, password_user: password_user} do
      conn =
        post(conn, ~p"/password_users/log_in", %{
          "password_user" => %{
            "email" => password_user.email,
            "password" => valid_password_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_instaclone_web_password_user_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the password_user in with return to", %{conn: conn, password_user: password_user} do
      conn =
        conn
        |> init_test_session(password_user_return_to: "/foo/bar")
        |> post(~p"/password_users/log_in", %{
          "password_user" => %{
            "email" => password_user.email,
            "password" => valid_password_user_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, password_user: password_user} do
      conn =
        conn
        |> post(~p"/password_users/log_in", %{
          "_action" => "registered",
          "password_user" => %{
            "email" => password_user.email,
            "password" => valid_password_user_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, password_user: password_user} do
      conn =
        conn
        |> post(~p"/password_users/log_in", %{
          "_action" => "password_updated",
          "password_user" => %{
            "email" => password_user.email,
            "password" => valid_password_user_password()
          }
        })

      assert redirected_to(conn) == ~p"/password_users/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/password_users/log_in", %{
          "password_user" => %{"email" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/password_users/log_in"
    end
  end

  describe "DELETE /password_users/log_out" do
    test "logs the password_user out", %{conn: conn, password_user: password_user} do
      conn = conn |> log_in_password_user(password_user) |> delete(~p"/password_users/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :password_user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the password_user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/password_users/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :password_user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
