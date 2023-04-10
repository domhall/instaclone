defmodule InstacloneWeb.Router do
  use InstacloneWeb, :router

  import InstacloneWeb.PasswordUserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {InstacloneWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_password_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", InstacloneWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", InstacloneWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:instaclone, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: InstacloneWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", InstacloneWeb do
    pipe_through [:browser, :redirect_if_password_user_is_authenticated]

    live_session :redirect_if_password_user_is_authenticated,
      on_mount: [{InstacloneWeb.PasswordUserAuth, :redirect_if_password_user_is_authenticated}] do
      live "/password_users/register", PasswordUserRegistrationLive, :new
      live "/password_users/log_in", PasswordUserLoginLive, :new
      live "/password_users/reset_password", PasswordUserForgotPasswordLive, :new
      live "/password_users/reset_password/:token", PasswordUserResetPasswordLive, :edit
    end

    post "/password_users/log_in", PasswordUserSessionController, :create
  end

  scope "/", InstacloneWeb do
    pipe_through [:browser, :require_authenticated_password_user]

    live_session :require_authenticated_password_user,
      on_mount: [{InstacloneWeb.PasswordUserAuth, :ensure_authenticated}] do
      live "/password_users/settings", PasswordUserSettingsLive, :edit
      live "/password_users/settings/confirm_email/:token", PasswordUserSettingsLive, :confirm_email
    end
  end

  scope "/", InstacloneWeb do
    pipe_through [:browser]

    delete "/password_users/log_out", PasswordUserSessionController, :delete

    live_session :current_password_user,
      on_mount: [{InstacloneWeb.PasswordUserAuth, :mount_current_password_user}] do
      live "/password_users/confirm/:token", PasswordUserConfirmationLive, :edit
      live "/password_users/confirm", PasswordUserConfirmationInstructionsLive, :new
    end
  end
end
