defmodule ReservationAppWeb.PageController do
  use ReservationAppWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    # uuid = Ecto.UUID.generate
    uuid =
      conn
      |> get_session(:_csrf_token)
      |> Base.encode64()

    conn
    |> put_session(:user_id, uuid)
    |> redirect(to: "/reservations")
  end
end
