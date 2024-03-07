defmodule ReservationAppWeb.PageController do
  use ReservationAppWeb, :controller

  def home(conn, _params) do
    uuid = get_csrf_token() |> Base.encode64()

    conn
    |> put_session(:user_id, uuid)
    |> redirect(to: "/reservations")
  end
end
