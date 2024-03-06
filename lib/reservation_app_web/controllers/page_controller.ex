defmodule ReservationAppWeb.PageController do
  use ReservationAppWeb, :controller

  def home(conn, _params) do
    uuid =
      conn
      |> get_session(:_csrf_token)
      |> Base.encode64()

    conn
    |> put_session(:user_id, uuid)
    |> redirect(to: "/reservations")
  end
end
