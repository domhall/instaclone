defmodule InstacloneWeb.PasswordUserAuthTest do
  use InstacloneWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias Instaclone.Identity
  alias InstacloneWeb.PasswordUserAuth
  import Instaclone.IdentityFixtures

  @remember_me_cookie "_instaclone_web_password_user_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, InstacloneWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{password_user: password_user_fixture(), conn: conn}
  end

  describe "log_in_password_user/3" do
    test "stores the password_user token in the session", %{conn: conn, password_user: password_user} do
      conn = PasswordUserAuth.log_in_password_user(conn, password_user)
      assert token = get_session(conn, :password_user_token)
      assert get_session(conn, :live_socket_id) == "password_users_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Identity.get_password_user_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, password_user: password_user} do
      conn = conn |> put_session(:to_be_removed, "value") |> PasswordUserAuth.log_in_password_user(password_user)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, password_user: password_user} do
      conn = conn |> put_session(:password_user_return_to, "/hello") |> PasswordUserAuth.log_in_password_user(password_user)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, password_user: password_user} do
      conn = conn |> fetch_cookies() |> PasswordUserAuth.log_in_password_user(password_user, %{"remember_me" => "true"})
      assert get_session(conn, :password_user_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :password_user_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_password_user/1" do
    test "erases session and cookies", %{conn: conn, password_user: password_user} do
      password_user_token = Identity.generate_password_user_session_token(password_user)

      conn =
        conn
        |> put_session(:password_user_token, password_user_token)
        |> put_req_cookie(@remember_me_cookie, password_user_token)
        |> fetch_cookies()
        |> PasswordUserAuth.log_out_password_user()

      refute get_session(conn, :password_user_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Identity.get_password_user_by_session_token(password_user_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "password_users_sessions:abcdef-token"
      InstacloneWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> PasswordUserAuth.log_out_password_user()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if password_user is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> PasswordUserAuth.log_out_password_user()
      refute get_session(conn, :password_user_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_password_user/2" do
    test "authenticates password_user from session", %{conn: conn, password_user: password_user} do
      password_user_token = Identity.generate_password_user_session_token(password_user)
      conn = conn |> put_session(:password_user_token, password_user_token) |> PasswordUserAuth.fetch_current_password_user([])
      assert conn.assigns.current_password_user.id == password_user.id
    end

    test "authenticates password_user from cookies", %{conn: conn, password_user: password_user} do
      logged_in_conn =
        conn |> fetch_cookies() |> PasswordUserAuth.log_in_password_user(password_user, %{"remember_me" => "true"})

      password_user_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> PasswordUserAuth.fetch_current_password_user([])

      assert conn.assigns.current_password_user.id == password_user.id
      assert get_session(conn, :password_user_token) == password_user_token

      assert get_session(conn, :live_socket_id) ==
               "password_users_sessions:#{Base.url_encode64(password_user_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, password_user: password_user} do
      _ = Identity.generate_password_user_session_token(password_user)
      conn = PasswordUserAuth.fetch_current_password_user(conn, [])
      refute get_session(conn, :password_user_token)
      refute conn.assigns.current_password_user
    end
  end

  describe "on_mount: mount_current_password_user" do
    test "assigns current_password_user based on a valid password_user_token ", %{conn: conn, password_user: password_user} do
      password_user_token = Identity.generate_password_user_session_token(password_user)
      session = conn |> put_session(:password_user_token, password_user_token) |> get_session()

      {:cont, updated_socket} =
        PasswordUserAuth.on_mount(:mount_current_password_user, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_password_user.id == password_user.id
    end

    test "assigns nil to current_password_user assign if there isn't a valid password_user_token ", %{conn: conn} do
      password_user_token = "invalid_token"
      session = conn |> put_session(:password_user_token, password_user_token) |> get_session()

      {:cont, updated_socket} =
        PasswordUserAuth.on_mount(:mount_current_password_user, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_password_user == nil
    end

    test "assigns nil to current_password_user assign if there isn't a password_user_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        PasswordUserAuth.on_mount(:mount_current_password_user, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_password_user == nil
    end
  end

  describe "on_mount: ensure_authenticated" do
    test "authenticates current_password_user based on a valid password_user_token ", %{conn: conn, password_user: password_user} do
      password_user_token = Identity.generate_password_user_session_token(password_user)
      session = conn |> put_session(:password_user_token, password_user_token) |> get_session()

      {:cont, updated_socket} =
        PasswordUserAuth.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_password_user.id == password_user.id
    end

    test "redirects to login page if there isn't a valid password_user_token ", %{conn: conn} do
      password_user_token = "invalid_token"
      session = conn |> put_session(:password_user_token, password_user_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: InstacloneWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = PasswordUserAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_password_user == nil
    end

    test "redirects to login page if there isn't a password_user_token ", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: InstacloneWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = PasswordUserAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_password_user == nil
    end
  end

  describe "on_mount: :redirect_if_password_user_is_authenticated" do
    test "redirects if there is an authenticated  password_user ", %{conn: conn, password_user: password_user} do
      password_user_token = Identity.generate_password_user_session_token(password_user)
      session = conn |> put_session(:password_user_token, password_user_token) |> get_session()

      assert {:halt, _updated_socket} =
               PasswordUserAuth.on_mount(
                 :redirect_if_password_user_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "Don't redirect is there is no authenticated password_user", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, _updated_socket} =
               PasswordUserAuth.on_mount(
                 :redirect_if_password_user_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end

  describe "redirect_if_password_user_is_authenticated/2" do
    test "redirects if password_user is authenticated", %{conn: conn, password_user: password_user} do
      conn = conn |> assign(:current_password_user, password_user) |> PasswordUserAuth.redirect_if_password_user_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if password_user is not authenticated", %{conn: conn} do
      conn = PasswordUserAuth.redirect_if_password_user_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_password_user/2" do
    test "redirects if password_user is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> PasswordUserAuth.require_authenticated_password_user([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/password_users/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> PasswordUserAuth.require_authenticated_password_user([])

      assert halted_conn.halted
      assert get_session(halted_conn, :password_user_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> PasswordUserAuth.require_authenticated_password_user([])

      assert halted_conn.halted
      assert get_session(halted_conn, :password_user_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> PasswordUserAuth.require_authenticated_password_user([])

      assert halted_conn.halted
      refute get_session(halted_conn, :password_user_return_to)
    end

    test "does not redirect if password_user is authenticated", %{conn: conn, password_user: password_user} do
      conn = conn |> assign(:current_password_user, password_user) |> PasswordUserAuth.require_authenticated_password_user([])
      refute conn.halted
      refute conn.status
    end
  end
end
