defmodule ReservationAppWeb.Live.ReservationsLive do
  alias ReservationApp.Reservations.Reservation
  alias ReservationApp.Reservations
  use ReservationAppWeb, :live_view

  @topic "reservations"

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
          reservations={@reservations}
          other_user_reservations={@other_user_reservations}
        />
      </.simple_form>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    ReservationAppWeb.Endpoint.subscribe(@topic)

    changeset = Reservations.change_reservation(%Reservation{}, %{user_id: session["user_id"]})

    {
      :ok,
      socket
      |> assign(:form, to_form(changeset))
      |> assign(:reservation, %Reservation{})
      |> assign(:user_id, session["user_id"])
      |> assign(:user_reservations, Reservations.list_reservations_for_user_id(session["user_id"]))
      |> assign(:other_user_reservations, Reservations.list_reservations_for_other_users(session["user_id"]))
    }
  end

  @impl true
  def handle_event("validate", params, socket) do
    form = %{
      "date" => params["date"]
    }

    {:noreply, assign(socket, :form, to_form(form))}
  end

  @impl true
  def handle_info({:updated_reservation, attrs}, socket) do
    reservation_attrs = %{date: attrs.range_start, user_id: socket.assigns.user_id}

    updated_socket =
      if Reservations.date_is_open?(reservation_attrs) do
        case Reservations.create_reservation(reservation_attrs) do
          {:ok, reservation} ->
            ReservationAppWeb.Endpoint.broadcast_from(self(), @topic, "date_reserved", reservation)

            socket
            |> assign(socket.assigns |> Map.delete(:flash))
            |> assign(:id, "date_picker")
            |> assign(:reservation, reservation)
            |> assign(:user_reservations, Reservations.list_reservations_for_user_id(reservation.user_id))
            |> assign(:other_user_reservations, Reservations.list_reservations_for_other_users(reservation.user_id))

          {:error, _} ->
            socket
        end
      else
        ReservationAppWeb.Endpoint.broadcast_from(self(), @topic, "date_already_taken", attrs)
        socket
      end

    date_picker_assigns = %{
      label: "Reserve a date!",
      id: "date_picker",
      form: socket.assigns.form,
      start_date_field: socket.assigns.form[:date],
      min: Date.utc_today() |> Date.add(-7),
      required: true,
      reservations: updated_socket.assigns.reservations,
      other_user_reservations: updated_socket.assigns.other_user_reservations
    }

    send_update(ReservationAppWeb.Components.DateRangePicker, date_picker_assigns)

    {:noreply, updated_socket}
  end

  @impl true
  def handle_info(%{topic: @topic, event: "date_reserved", payload: state} = sig, socket) do
    {
      :noreply,
      socket
      |> assign(socket.assigns |> Map.delete(:flash))
      |> assign(%{other_user_reservations: [state | socket.assigns.other_user_reservations]})
    }
  end

  @impl true
  def handle_info(%{topic: @topic, event: "date_already_taken", payload: state} = sig, socket) do
    {
      :noreply,
      socket
    }
  end
end
