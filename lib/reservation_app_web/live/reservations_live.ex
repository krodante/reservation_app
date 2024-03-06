defmodule ReservationAppWeb.Live.ReservationsLive do
  use ReservationAppWeb, :live_view

  alias ReservationApp.LocksServer
  alias ReservationApp.Reservations
  alias ReservationApp.Reservations.Reservation
  alias ReservationAppWeb.Components.DateRangePicker
  alias ReservationAppWeb.Endpoint

  @topic "reservations"

  @impl true
  def render(assigns) do
    ~H"""
    <div :if={@message}>
      <h3><%= @message %></h3>
    </div>

    <div :if={@confirmation}>
      <.button phx-click="confirm-date">
        <%= "Confirm #{@locking_date |> Date.to_string()}" %>
      </.button>
      <span><%= "#{@count} seconds left to confirm" %></span>
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
    """
  end

  @impl true
  def mount(_params, %{"user_id" => user_id}, socket) do
    Endpoint.subscribe(@topic)

    changeset =
      Reservations.change_reservation(%Reservation{}, %{
        user_id: user_id,
        user_slug: MnemonicSlugs.generate_slug()
      })

    {
      :ok,
      socket
      |> assign(:form, to_form(changeset))
      |> reset_assigns()
      |> assign(
        :other_user_reservations,
        Reservations.list_reservations_for_other_users(user_id)
      )
      |> assign(:reservation, %Reservation{})
      |> assign(:user_id, user_id)
      |> assign(
        :user_reservations,
        Reservations.list_reservations_for_user_id(user_id)
      )
    }
  end

  @impl true
  def handle_event("confirm-date", _params, socket) do
    res_attrs = %{date: socket.assigns.locking_date, user_id: socket.assigns.user_id}

    updated_socket =
      case Reservations.create_reservation(res_attrs) do
        {:ok, reservation} ->
          Endpoint.broadcast_from(self(), @topic, "date_reserved", reservation)
          LocksServer.remove(reservation.date)
          LocksServer.remove(reservation.user_id)
          Process.cancel_timer(socket.assigns.lock_timer)

          socket
          |> assign(socket.assigns |> Map.delete(:flash))
          |> reset_assigns()
          |> assign(
            :other_user_reservations,
            Reservations.list_reservations_for_other_users(reservation.user_id)
          )
          |> assign(:reservation, reservation)
          |> assign(
            :user_reservations,
            Reservations.list_reservations_for_user_id(reservation.user_id)
          )

        {:error, _} ->
          socket
      end

    {:noreply, updated_socket}
  end

  @impl true
  def handle_info({:updated_reservation, attrs}, socket) do
    res_attrs = %{date: attrs.range_start, user_id: socket.assigns.user_id}

    updated_socket =
      with {:date_available, true} <- Reservations.date_is_available?(res_attrs),
           {:already_locking, false} <- Reservations.already_locking?(res_attrs) do
        LocksServer.insert(res_attrs.date, res_attrs.user_id)
        LocksServer.insert(res_attrs.user_id, res_attrs.date)
        Endpoint.broadcast_from(self(), @topic, "lock_started", res_attrs)
        lock_timer = Process.send_after(self(), "lock_ended", 5000)
        :erlang.send_after(1000, self(), :tick)

        socket
        |> assign(socket.assigns |> Map.delete(:flash))
        |> assign(:confirmation, true)
        |> assign(:locking_date, res_attrs.date)
        |> assign(:lock_timer, lock_timer)
        |> assign(:count, 5)
      else
        {:date_available, false} ->
          socket

        {:already_locking, true} ->
          send(self(), "already_locking")
          socket
      end

    send_update(DateRangePicker, date_picker_assigns(socket, updated_socket))

    {:noreply, updated_socket}
  end

  @impl true
  def handle_info(:tick, %{assigns: %{count: 0}} = socket) do
    {:noreply, assign(socket, :count, 0)}
  end

  @impl true
  def handle_info(:tick, %{assigns: %{count: count}} = socket) when count <= 5 do
    :erlang.send_after(1000, self(), :tick)

    {:noreply, assign(socket, :count, count - 1)}
  end

  @impl true
  def handle_info(:tick, socket), do: {:noreply, socket}

  @impl true
  def handle_info(%{topic: @topic, event: "date_reserved", payload: reservation}, socket) do
    {
      :noreply,
      socket
      |> assign(socket.assigns |> Map.delete(:flash))
      |> assign(:count, 0)
      |> assign(:locking_date, nil)
      |> assign(:message, nil)
      |> assign(:other_user_reservations, [reservation | socket.assigns.other_user_reservations])
    }
  end

  @impl true
  def handle_info(%{topic: @topic, event: "lock_started", payload: reservation}, socket) do
    {
      :noreply,
      socket
      |> assign(:count, 5)
      |> assign(:locking_date, reservation.date)
    }
  end

  @impl true
  def handle_info(%{topic: @topic, event: "lock_ended", payload: _reservation}, socket) do
    {:noreply, reset_assigns(socket)}
  end

  @impl true
  def handle_info("already_locking", socket) do
    {:noreply, assign(socket, :message, "You can only reserve one date at a time!")}
  end

  @impl true
  def handle_info("lock_ended", socket) do
    Endpoint.broadcast_from(self(), @topic, "lock_ended", %{})

    {:noreply, reset_assigns(socket)}
  end

  defp reset_assigns(socket) do
    socket
    |> assign(:confirmation, false)
    |> assign(:count, 0)
    |> assign(:lock_timer, nil)
    |> assign(:locking_date, nil)
    |> assign(:message, nil)
  end

  defp date_picker_assigns(socket, updated_socket) do
    %{
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
  end
end
