defmodule ReservationApp.Repo do
  use Ecto.Repo,
    otp_app: :reservation_app,
    adapter: Ecto.Adapters.Postgres
end
