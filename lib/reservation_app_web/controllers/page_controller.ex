defmodule ReservationAppWeb.PageController do
  use ReservationAppWeb, :controller

  def home(conn, _params) do
    uuid = get_csrf_token() |> Base.encode64()
    user_slug = MnemonicSlugs.generate_slug()

    conn
    |> put_session(:user_id, uuid)
    |> put_session(:user_slug, user_slug)
    |> redirect(to: "/reservations")
  end
end
