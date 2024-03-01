defmodule ReservationAppWeb.ReservationsLive do
  alias ReservationApp.Reservations.Reservation
  alias ReservationApp.Reservations
  use ReservationAppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
      <.simple_form for={@form} id="reservation_form" phx-change="validate" phx-submit="save">
        <.date_picker
          label="Reserve a date!"
          id="date_picker"
          form={@form}
          start_date_field={@form[:date]}
          min={Date.utc_today() |> Date.add(-7)}
          required={true}
        />
      </.simple_form>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    reservation =
      Reservations.get_reservation_by_user_id(session["user_id"]) || %Reservation{}

    changeset = Reservations.change_reservation(reservation, %{})

    {
      :ok,
      socket
      |> assign(:form, to_form(changeset))
      |> assign(:reservation, reservation)
      |> assign(:user_id, session["user_id"])
      |> assign(:reservations, Reservations.list_reservations())
    }
  end

  @impl true
  def handle_event("validate", params, socket) do
    IO.inspect("in validate")
    form = %{
      "date" => params["date"]
    }

    {:noreply, assign(socket, :form, to_form(form))}
  end

  @impl true
  def handle_info({:updated_reservation, attrs}, socket) do
    reservation = socket.assigns.reservation
    date = attrs.range_start
    # form = attrs.form

    # new_form =
    #   Phoenix.HTML.FormData.to_form(
    #     %{
    #       "date" => attrs.date
    #     },
    #     id: form.id
    #   )

    # updated_socket =
    #   socket
    #   |> assign(:reservation, reservation)
    #   |> assign(:id, attrs.id)
    #   |> assign(:new_form, new_form)

    # send_update(
    #   ReservationAppWeb.ReservationsLive,
    #   updated_socket.assigns
    #   |> Map.delete(:flash)
    #   |> Map.delete(:streams)
    # )

    {:noreply, socket}
  end
end
