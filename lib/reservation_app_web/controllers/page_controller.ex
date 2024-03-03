defmodule ReservationAppWeb.PageController do
  use ReservationAppWeb, :controller

  def home(conn, _params) do
    uuid = Plug.CSRFProtection.get_csrf_token_for("/") |> Base.encode64()

    conn
    |> put_session(:user_id, uuid)
    |> redirect(to: "/reservations")
  end
end
