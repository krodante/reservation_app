defmodule ReservationAppWeb.Live.ReservationsLive do
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
          reservations={@reservations}
          other_user_reservations={@other_user_reservations}
        />
      </.simple_form>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    changeset = Reservations.change_reservation(%Reservation{}, %{user_id: session["user_id"]})

    {
      :ok,
      socket
      |> assign(:form, to_form(changeset))
      |> assign(:reservation, %Reservation{})
      |> assign(:user_id, session["user_id"])
      |> assign(:reservations, Reservations.list_reservations_for_user_id(session["user_id"]))
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
    updated_socket =
      case Reservations.create_reservation(%{date: attrs.range_start, user_id: socket.assigns.user_id}) do
        {:ok, reservation} ->
            socket
            |> assign(socket.assigns |> Map.delete(:flash))
            |> assign(:id, "date_picker")
            |> assign(:reservation, reservation)
        {:error, _message} -> socket
      end

    date_picker_assigns = %{
      label: "Reserve a date!",
      id: "date_picker",
      form: socket.assigns.form,
      start_date_field: socket.assigns.form[:date],
      min: Date.utc_today() |> Date.add(-7),
      required: true,
      reservations: Reservations.list_reservations_for_user_id(socket.assigns.user_id),
      other_user_reservations: Reservations.list_reservations_for_other_users(socket.assigns.user_id)
    }

    send_update(ReservationAppWeb.Components.DateRangePicker, date_picker_assigns)

    {:noreply, updated_socket}
  end
end
