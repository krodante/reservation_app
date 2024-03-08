defmodule ReservationApp.Reservations do
  import Ecto.Query

  alias ReservationApp.LocksServer
  alias ReservationApp.Repo
  alias ReservationApp.Reservations.Event
  alias ReservationApp.Reservations.Reservation

  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end

  def list_events do
    from(e in Event, order_by: [desc: :inserted_at])
    |> Repo.all()
  end

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
    case date_is_open?(date) && date_not_locked?(date) do
      true -> {:date_available, true}
      false -> {:date_available, false}
    end
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
         {:not_expired, true} <- {:not_expired, :erlang.system_time(:second) < expiry} do
      false
    else
      [] ->
        true

      {:not_expired, false} ->
        LocksServer.remove(date)
        true
    end
  end

  def already_locking?(%{user_id: user_id}) do
    result = :ets.lookup(:locked_dates, user_id)

    with [{_key, _value, expiry}] <- result,
         {:not_expired, true} <- {:not_expired, :erlang.system_time(:second) < expiry} do
      {:already_locking, true}
    else
      [] ->
        {:already_locking, false}

      {:not_expired, false} ->
        LocksServer.remove(user_id)
        {:already_locking, false}
    end
  end
end
