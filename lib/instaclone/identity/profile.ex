defmodule Instaclone.Identity.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "profiles" do
    field :handle, :string
    belongs_to :user, Instaclone.Identity.User

    timestamps()
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:handle])
    |> validate_required([:handle])
  end
end
