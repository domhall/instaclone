defmodule Instaclone.Identity do
  # @behaviour InstacloneDomain.IdentityContext.Ports.UserRepository
  @moduledoc """
  The Identity context.
  """

  import Ecto.Query, warn: false
  alias Instaclone.Repo

  alias Instaclone.Identity.{PasswordUser, PasswordUserToken, PasswordUserNotifier}

  ## Database getters

  @doc """
  Gets a password_user by email.

  ## Examples

      iex> get_password_user_by_email("foo@example.com")
      %PasswordUser{}

      iex> get_password_user_by_email("unknown@example.com")
      nil

  """
  def get_password_user_by_email(email) when is_binary(email) do
    Repo.get_by(PasswordUser, email: email)
  end

  @doc """
  Gets a password_user by email and password.

  ## Examples

      iex> get_password_user_by_email_and_password("foo@example.com", "correct_password")
      %PasswordUser{}

      iex> get_password_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_password_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    password_user = Repo.get_by(PasswordUser, email: email)
    if PasswordUser.valid_password?(password_user, password), do: password_user
  end

  @doc """
  Gets a single password_user.

  Raises `Ecto.NoResultsError` if the PasswordUser does not exist.

  ## Examples

      iex> get_password_user!(123)
      %PasswordUser{}

      iex> get_password_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_password_user!(id), do: Repo.get!(PasswordUser, id)

  ## Password user registration

  @doc """
  Registers a password_user.

  ## Examples

      iex> register_password_user(%{field: value})
      {:ok, %PasswordUser{}}

      iex> register_password_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_password_user(attrs) do
    email = attrs["email"]
    registered_user = InstacloneDomain.IdentityContext.register_user(email)

    %PasswordUser{}
    |> PasswordUser.registration_changeset(attrs)
    |> PasswordUser.associate_user_changeset(%{user_id: registered_user[:id]})
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking password_user changes.

  ## Examples

      iex> change_password_user_registration(password_user)
      %Ecto.Changeset{data: %PasswordUser{}}

  """
  def change_password_user_registration(%PasswordUser{} = password_user, attrs \\ %{}) do
    PasswordUser.registration_changeset(password_user, attrs,
      hash_password: false,
      validate_email: false
    )
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the password_user email.

  ## Examples

      iex> change_password_user_email(password_user)
      %Ecto.Changeset{data: %PasswordUser{}}

  """
  def change_password_user_email(password_user, attrs \\ %{}) do
    PasswordUser.email_changeset(password_user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_password_user_email(password_user, "valid password", %{email: ...})
      {:ok, %PasswordUser{}}

      iex> apply_password_user_email(password_user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_password_user_email(password_user, password, attrs) do
    password_user
    |> PasswordUser.email_changeset(attrs)
    |> PasswordUser.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the password_user email using the given token.

  If the token matches, the password_user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_password_user_email(password_user, token) do
    context = "change:#{password_user.email}"

    with {:ok, query} <- PasswordUserToken.verify_change_email_token_query(token, context),
         %PasswordUserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(password_user_email_multi(password_user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp password_user_email_multi(password_user, email, context) do
    changeset =
      password_user
      |> PasswordUser.email_changeset(%{email: email})
      |> PasswordUser.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:password_user, changeset)
    |> Ecto.Multi.delete_all(
      :tokens,
      PasswordUserToken.password_user_and_contexts_query(password_user, [context])
    )
  end

  @doc ~S"""
  Delivers the update email instructions to the given password_user.

  ## Examples

      iex> deliver_password_user_update_email_instructions(password_user, current_email, &url(~p"/password_users/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_password_user_update_email_instructions(
        %PasswordUser{} = password_user,
        current_email,
        update_email_url_fun
      )
      when is_function(update_email_url_fun, 1) do
    {encoded_token, password_user_token} =
      PasswordUserToken.build_email_token(password_user, "change:#{current_email}")

    Repo.insert!(password_user_token)

    PasswordUserNotifier.deliver_update_email_instructions(
      password_user,
      update_email_url_fun.(encoded_token)
    )
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the password_user password.

  ## Examples

      iex> change_password_user_password(password_user)
      %Ecto.Changeset{data: %PasswordUser{}}

  """
  def change_password_user_password(password_user, attrs \\ %{}) do
    PasswordUser.password_changeset(password_user, attrs, hash_password: false)
  end

  @doc """
  Updates the password_user password.

  ## Examples

      iex> update_password_user_password(password_user, "valid password", %{password: ...})
      {:ok, %PasswordUser{}}

      iex> update_password_user_password(password_user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_password_user_password(password_user, password, attrs) do
    changeset =
      password_user
      |> PasswordUser.password_changeset(attrs)
      |> PasswordUser.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:password_user, changeset)
    |> Ecto.Multi.delete_all(
      :tokens,
      PasswordUserToken.password_user_and_contexts_query(password_user, :all)
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{password_user: password_user}} -> {:ok, password_user}
      {:error, :password_user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_password_user_session_token(password_user) do
    {token, password_user_token} = PasswordUserToken.build_session_token(password_user)
    Repo.insert!(password_user_token)
    token
  end

  @doc """
  Gets the password_user with the given signed token.
  """
  def get_password_user_by_session_token(token) do
    {:ok, query} = PasswordUserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_password_user_session_token(token) do
    Repo.delete_all(PasswordUserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given password_user.

  ## Examples

      iex> deliver_password_user_confirmation_instructions(password_user, &url(~p"/password_users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_password_user_confirmation_instructions(confirmed_password_user, &url(~p"/password_users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_password_user_confirmation_instructions(
        %PasswordUser{} = password_user,
        confirmation_url_fun
      )
      when is_function(confirmation_url_fun, 1) do
    if password_user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, password_user_token} =
        PasswordUserToken.build_email_token(password_user, "confirm")

      Repo.insert!(password_user_token)

      PasswordUserNotifier.deliver_confirmation_instructions(
        password_user,
        confirmation_url_fun.(encoded_token)
      )
    end
  end

  @doc """
  Confirms a password_user by the given token.

  If the token matches, the password_user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_password_user(token) do
    with {:ok, query} <- PasswordUserToken.verify_email_token_query(token, "confirm"),
         %PasswordUser{} = password_user <- Repo.one(query),
         {:ok, %{password_user: password_user}} <-
           Repo.transaction(confirm_password_user_multi(password_user)) do
      {:ok, password_user}
    else
      _ -> :error
    end
  end

  defp confirm_password_user_multi(password_user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:password_user, PasswordUser.confirm_changeset(password_user))
    |> Ecto.Multi.delete_all(
      :tokens,
      PasswordUserToken.password_user_and_contexts_query(password_user, ["confirm"])
    )
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given password_user.

  ## Examples

      iex> deliver_password_user_reset_password_instructions(password_user, &url(~p"/password_users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_password_user_reset_password_instructions(
        %PasswordUser{} = password_user,
        reset_password_url_fun
      )
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, password_user_token} =
      PasswordUserToken.build_email_token(password_user, "reset_password")

    Repo.insert!(password_user_token)

    PasswordUserNotifier.deliver_reset_password_instructions(
      password_user,
      reset_password_url_fun.(encoded_token)
    )
  end

  @doc """
  Gets the password_user by reset password token.

  ## Examples

      iex> get_password_user_by_reset_password_token("validtoken")
      %PasswordUser{}

      iex> get_password_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_password_user_by_reset_password_token(token) do
    with {:ok, query} <- PasswordUserToken.verify_email_token_query(token, "reset_password"),
         %PasswordUser{} = password_user <- Repo.one(query) do
      password_user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the password_user password.

  ## Examples

      iex> reset_password_user_password(password_user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %PasswordUser{}}

      iex> reset_password_user_password(password_user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_password_user_password(password_user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:password_user, PasswordUser.password_changeset(password_user, attrs))
    |> Ecto.Multi.delete_all(
      :tokens,
      PasswordUserToken.password_user_and_contexts_query(password_user, :all)
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{password_user: password_user}} -> {:ok, password_user}
      {:error, :password_user, changeset, _} -> {:error, changeset}
    end
  end
end
