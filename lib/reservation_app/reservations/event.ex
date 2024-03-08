defmodule ReservationApp.Reservations.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [:date, :user_id, :user_slug, :name]

  schema "events" do
    field(:date, :date)
    field(:user_id, :string)
    field(:user_slug, :string)
    field(:name, :string)

    timestamps()
  end

  def changeset(event, attrs \\ %{}) do
    event
    |> cast(attrs, @fields)
  end
end
