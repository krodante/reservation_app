defmodule ReservationApp.Reservations do
  import Ecto.Query

  alias ReservationApp.LocksServer
  alias ReservationApp.Repo
  alias ReservationApp.Reservations.Reservation

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

  def date_is_available?(%{date: date}) do
    date_is_open?(date) && date_not_locked?(date)
  end

  def date_is_available?(_), do: true

  def date_is_open?(date) do
    from(r in Reservation, where: r.date == ^date)
    |> Repo.one()
    |> is_nil()
  end

  def date_not_locked?(date) do
    result = :ets.lookup(:locked_dates, date)

    with [{_key, _value, expiry}] <- result,
         true <- :erlang.system_time(:second) < expiry do
      false
    else
      [] ->
        true

      false ->
        LocksServer.remove(date)
        true
    end
  end
end
