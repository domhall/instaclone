defmodule InstacloneWeb.PasswordUserResetPasswordLive do
  use InstacloneWeb, :live_view

  alias Instaclone.Identity

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">Reset Password</.header>

      <.simple_form
        for={@form}
        id="reset_password_form"
        phx-submit="reset_password"
        phx-change="validate"
      >
        <.error :if={@form.errors != []}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={@form[:password]} type="password" label="New password" required />
        <.input
          field={@form[:password_confirmation]}
          type="password"
          label="Confirm new password"
          required
        />
        <:actions>
          <.button phx-disable-with="Resetting..." class="w-full">Reset Password</.button>
        </:actions>
      </.simple_form>

      <p class="text-center text-sm mt-4">
        <.link href={~p"/password_users/register"}>Register</.link>
        | <.link href={~p"/password_users/log_in"}>Log in</.link>
      </p>
    </div>
    """
  end

  def mount(params, _session, socket) do
    socket = assign_password_user_and_token(socket, params)

    form_source =
      case socket.assigns do
        %{password_user: password_user} ->
          Identity.change_password_user_password(password_user)

        _ ->
          %{}
      end

    {:ok, assign_form(socket, form_source), temporary_assigns: [form: nil]}
  end

  # Do not log in the password_user after reset password to avoid a
  # leaked token giving the password_user access to the account.
  def handle_event("reset_password", %{"password_user" => password_user_params}, socket) do
    case Identity.reset_password_user_password(socket.assigns.password_user, password_user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully.")
         |> redirect(to: ~p"/password_users/log_in")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate", %{"password_user" => password_user_params}, socket) do
    changeset = Identity.change_password_user_password(socket.assigns.password_user, password_user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_password_user_and_token(socket, %{"token" => token}) do
    if password_user = Identity.get_password_user_by_reset_password_token(token) do
      assign(socket, password_user: password_user, token: token)
    else
      socket
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: ~p"/")
    end
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "password_user"))
  end
end
