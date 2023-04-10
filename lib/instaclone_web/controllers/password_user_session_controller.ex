defmodule InstacloneWeb.PasswordUserSessionController do
  use InstacloneWeb, :controller

  alias Instaclone.Identity
  alias InstacloneWeb.PasswordUserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:password_user_return_to, ~p"/password_users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"password_user" => password_user_params}, info) do
    %{"email" => email, "password" => password} = password_user_params

    if password_user = Identity.get_password_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> PasswordUserAuth.log_in_password_user(password_user, password_user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/password_users/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> PasswordUserAuth.log_out_password_user()
  end
end
