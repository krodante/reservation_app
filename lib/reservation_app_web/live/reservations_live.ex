defmodule ReservationAppWeb.Live.ReservationsLive do
  use ReservationAppWeb, :live_view

  alias ReservationApp.LocksServer
  alias ReservationApp.Reservations
  alias ReservationApp.Reservations.Reservation

  @topic "reservations"

  @impl true
  def render(assigns) do
    ~H"""
    <div :if={@confirmation}>
      <.button phx-click="confirm-date">Confirm <%= @locking_date |> Date.to_string() %></.button>
    </div>
    <.simple_form for={@form} id="reservation_form">
      <.date_picker
        label="Reserve a date!"
        id="date_picker"
        form={@form}
        start_date_field={@form[:date]}
        min={Date.utc_today() |> Date.add(-7)}
        required={true}
        reservations={@user_reservations}
        other_user_reservations={@other_user_reservations}
        locking_date={@locking_date}
      />
    </.simple_form>

    <%!-- <div>
        <table>
          <%= for
        </table>
      </div> --%>
    """
  end

  @impl true
  def mount(_params, %{"user_id" => user_id}, socket) do
    ReservationAppWeb.Endpoint.subscribe(@topic)

    changeset = Reservations.change_reservation(%Reservation{}, %{user_id: user_id, user_slug: MnemonicSlugs.generate_slug()})

    {
      :ok,
      socket
      |> assign(:form, to_form(changeset))
      |> assign(:confirmation, false)
      |> assign(:lock_started, false)
      |> assign(:locking_user, nil)
      |> assign(:locking_date, nil)
      |> assign(:timer_ref, nil)
      |> assign(:reservation, %Reservation{})
      |> assign(:user_id, user_id)
      |> assign(
        :user_reservations,
        Reservations.list_reservations_for_user_id(user_id)
      )
      |> assign(
        :other_user_reservations,
        Reservations.list_reservations_for_other_users(user_id)
      )
    }
  end

  @impl true
  def handle_event("confirm-date", _params, socket) do
    reservation_attrs = %{date: socket.assigns.locking_date, user_id: socket.assigns.user_id}

    updated_socket =
      case Reservations.create_reservation(reservation_attrs) do
        {:ok, reservation} ->
          ReservationAppWeb.Endpoint.broadcast_from(self(), @topic, "date_reserved", reservation)
          Process.cancel_timer(socket.assigns.timer_ref)

          socket
          |> assign(socket.assigns |> Map.delete(:flash))
          |> assign(:id, "date_picker")
          |> assign(:reservation, reservation)
          |> assign(
            :user_reservations,
            Reservations.list_reservations_for_user_id(reservation.user_id)
          )
          |> assign(
            :other_user_reservations,
            Reservations.list_reservations_for_other_users(reservation.user_id)
          )
          |> assign(:locking_date, nil)
          |> assign(:confirmation, false)
          |> assign(:timer_ref, nil)

        {:error, _} ->
          socket
      end

    {:noreply, updated_socket}
  end

  @impl true
  def handle_info({:updated_reservation, attrs}, socket) do
    reservation_attrs = %{date: attrs.range_start, user_id: socket.assigns.user_id}

    updated_socket =
      if Reservations.date_is_available?(reservation_attrs) do
        LocksServer.insert(reservation_attrs.date, reservation_attrs.user_id)

        ReservationAppWeb.Endpoint.broadcast_from(
          self(),
          @topic,
          "lock_started",
          reservation_attrs
        )

        timer_ref = Process.send_after(self(), "lock_ended", 5000)

        socket
        |> assign(socket.assigns |> Map.delete(:flash))
        |> assign(:confirmation, true)
        |> assign(:locking_date, reservation_attrs.date)
        |> assign(:timer_ref, timer_ref)
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
      reservations: updated_socket.assigns.user_reservations,
      other_user_reservations: updated_socket.assigns.other_user_reservations,
      locking_date: updated_socket.assigns.locking_date
    }

    send_update(ReservationAppWeb.Components.DateRangePicker, date_picker_assigns)

    {:noreply, updated_socket}
  end

  @impl true
  def handle_info(%{topic: @topic, event: "date_reserved", payload: state}, socket) do
    {
      :noreply,
      socket
      |> assign(socket.assigns |> Map.delete(:flash))
      |> assign(:other_user_reservations, [state | socket.assigns.other_user_reservations])
      |> assign(:locking_date, nil)
    }
  end

  @impl true
  def handle_info(%{topic: @topic, event: "date_already_taken", payload: _state}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{topic: @topic, event: "lock_started", payload: state}, socket) do
    {
      :noreply,
      socket
      |> assign(:lock_started, true)
      |> assign(:locking_user, state.user_id)
      |> assign(:locking_date, state.date)
    }
  end

  @impl true
  def handle_info("lock_ended", socket) do
    ReservationAppWeb.Endpoint.broadcast_from(self(), @topic, "lock_ended", %{})

    {
      :noreply,
      socket
      |> assign(:lock_started, false)
      |> assign(:locking_user, nil)
      |> assign(:locking_date, nil)
      |> assign(:confirmation, false)
      |> assign(:timer_ref, nil)
    }
  end

  @impl true
  def handle_info(%{topic: @topic, event: "lock_ended", payload: _state}, socket) do
    {
      :noreply,
      socket
      |> assign(:lock_started, false)
      |> assign(:locking_user, nil)
      |> assign(:locking_date, nil)
      |> assign(:confirmation, false)
      |> assign(:timer_ref, nil)
    }
  end
end
