defmodule ReservationApp.Reservations.Reservation do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [:date, :user_id, :user_slug]

  schema "reservations" do
    field(:date, :date)
    field(:user_id, :string)
    field(:user_slug, :string)
  end

  def changeset(reservation, attrs \\ %{}) do
    reservation
    |> cast(attrs, @fields)
  end
end
