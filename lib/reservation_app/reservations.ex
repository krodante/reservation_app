defmodule ReservationApp.Reservations do
  alias ReservationApp.Reservations.Reservation
  alias ReservationApp.Repo

  def create_reservation(attrs \\ %{}) do
    %Reservation{}
    |> Reservation.changeset(attrs)
    |> Repo.insert()
  end
end
