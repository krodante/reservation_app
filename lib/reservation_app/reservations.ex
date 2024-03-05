defmodule ReservationApp.Reservations do
  import Ecto.Query

  alias ReservationApp.Reservations.Reservation
  alias ReservationApp.Repo

  def create_reservation(attrs \\ %{}) do
    %Reservation{}
    |> Reservation.changeset(attrs)
    |> Repo.insert()
  end

  def change_reservation(%Reservation{} = reservation, attrs \\ %{}) do
    Reservation.changeset(reservation, attrs)
  end

  def get_reservation_by_user_id(id) do
    from(r in Reservation, where: r.user_id == ^id)
    |> Repo.one()
  end

  def list_reservations do
    Reservation
    |> Repo.all()
  end

  def list_reservations_for_user_id(id) do
    from(r in Reservation, where: r.user_id == ^id)
    |> Repo.all()
  end

  def list_reservations_for_other_users(id) do
    from(r in Reservation, where: r.user_id != ^id)
    |> Repo.all()
  end

  def date_is_open?(%{date: date}) do
    from(r in Reservation, where: r.date == ^date)
    |> Repo.one()
    |> is_nil()
  end

  def date_is_open?(_), do: true
end
