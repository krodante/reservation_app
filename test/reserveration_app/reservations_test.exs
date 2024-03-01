defmodule ReserverationApp.ReservationsTest do
  alias ReservationApp.Reservations
  use ReservationApp.DataCase

  describe "create_reservation/1" do
    test "saves a reservation" do
      attrs = %{
        date: Date.utc_today(),
        user_id: "user_id",
        user_slug: "user_slug"
      }

      {:ok, result} = Reservations.create_reservation(attrs)

      assert result.user_id == "user_id"
    end
  end
end
