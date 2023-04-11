defmodule Instaclone.IdentityFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Instaclone.Identity` context.
  """

  def unique_password_user_email, do: "password_user#{System.unique_integer()}@example.com"
  def valid_password_user_password, do: "hello world!"

  def valid_password_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_password_user_email(),
      password: valid_password_user_password(),
      user_id: Ecto.UUID.generate()
    })
  end

  def valid_password_user_form_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_password_user_email(),
      password: valid_password_user_password()
    })
  end

  def password_user_fixture(attrs \\ %{}) do
    {:ok, password_user} =
      attrs
      |> valid_password_user_attributes()
      |> Instaclone.Identity.register_password_user()

    password_user
  end

  def password_user_form_fixture(attrs \\ %{}) do
    {:ok, password_user} =
      attrs
      |> valid_password_user_form_attributes()
      |> Instaclone.Identity.register_password_user()

    password_user
  end

  def extract_password_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
