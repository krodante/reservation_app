defmodule ReservationAppWeb.Components.DateRangePicker do
  use ReservationAppWeb, :live_component

  @week_start_at :sunday
  @initial_state :set_start

  @impl true
  def render(assigns) do
    ~H"""
    <div class="date-range-picker">
      <.input field={@start_date_field} type="hidden" />
      <.input :if={@is_range?} field={@end_date_field} type="hidden" />

      <div :if={@calendar?} id={"#{@id}_calendar"} class="absolute z-50 w-72" phx-target={@myself}>
        <div
          id="calendar_background"
          class="w-full bg-white rounded-md ring-1 ring-black ring-opacity-2 focus:outline-none p-3"
        >
          <div id="calendar_header" class="flex justify-between">
            <div id="button_left">
              <button
                type="button"
                phx-target={@myself}
                phx-click="prev-month"
                class="p-1.5 text-gray-400 hover:text-gray-500"
              >
                <.icon name="hero-arrow-left" />
              </button>
            </div>

            <div id="current_month_year" class="self-center">
              <%= @current.month %>
            </div>

            <div id="button_right">
              <button
                type="button"
                phx-target={@myself}
                phx-click="next-month"
                class="p-1.5 text-gray-400 hover:text-gray-500"
              >
                <.icon name="hero-arrow-right" />
              </button>
            </div>
          </div>

          <div id="click_today" class="text-sm text-center">
            <.link phx-click="today" phx-target={@myself} class="text-gray-700 hover:text-gray-500">
              Today
            </.link>
          </div>

          <div
            id="calendar_weekdays"
            class="text-center mt-6 grid grid-cols-7 text-xs leading-6 text-gray-500"
          >
            <div :for={week_day <- List.first(@current.week_rows)}>
              <%= Calendar.strftime(week_day, "%a") %>
            </div>
          </div>

          <div
            id={"calendar_days_#{String.replace(@current.month, " ", "-")}"}
            class="isolate mt-2 grid grid-cols-7 gap-px text-sm"
            phx-hook="DaterangeHover"
          >
            <button
              :for={day <- Enum.flat_map(@current.week_rows, & &1)}
              type="button"
              phx-target={@myself}
              phx-click="pick-date"
              phx-value-date={Calendar.strftime(day, "%Y-%m-%d") <> "T00:00:00Z"}
              class={[
                "calendar-day overflow-hidden py-1.5 h-10 w-auto focus:z-10 w-full",
                today?(day) && "font-bold border border-black",
                before_min_date?(day, @min) && "text-gray-300 cursor-not-allowed",
                !before_min_date?(day, @min) && "hover:bg-blue-300 hover:border hover:border-black",
                other_month?(day, @current.date) && "text-gray-500",
                reserved_date?(day, @reservations) &&
                  "hover:bg-blue-500 bg-blue-500 text-white",
                reserved_date?(day, @other_user_reservations) &&
                  "hover:bg-red-500 bg-red-500 text-white",
                locking_date?(day, @locking_date) &&
                  "hover:bg-yellow-500 bg-yellow-500 text-black"
              ]}
            >
              <time
                class="mx-auto flex h-6 w-6 items-center justify-center rounded-full"
                datetime={Calendar.strftime(day, "%Y-%m-%d")}
              >
                <%= Calendar.strftime(day, "%d") %>
              </time>
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    current_date = Date.utc_today()

    {
      :ok,
      socket
      |> assign(:calendar?, true)
      |> assign(:current, format_date(current_date))
      |> assign(:is_range?, false)
      |> assign(:range_start, nil)
      |> assign(:range_end, nil)
      |> assign(:hover_range_end, nil)
      |> assign(:readonly, false)
      |> assign(:reserved_date, nil)
      |> assign(:form, nil)
      |> assign(:reservations, [])
      |> assign(:other_user_reservations, [])
    }
  end

  @impl true
  def update(assigns, socket) do
    range_start = from_str!(assigns.start_date_field.value)
    current_date = socket.assigns.current.date

    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:current, format_date(current_date))
      |> assign(:range_start, range_start)
      |> assign(:state, @initial_state)
    }
  end

  @impl true
  def handle_event("today", _, socket) do
    new_date = Date.utc_today()
    {:noreply, socket |> assign(:current, format_date(new_date))}
  end

  @impl true
  def handle_event("prev-month", _, socket) do
    new_date = new_date(socket.assigns)
    {:noreply, socket |> assign(:current, format_date(new_date))}
  end

  @impl true
  def handle_event("next-month", _, socket) do
    last_row = socket.assigns.current.week_rows |> List.last()
    new_date = next_month_new_date(socket.assigns.current.date, last_row)
    {:noreply, socket |> assign(:current, format_date(new_date))}
  end

  @impl true
  def handle_event("pick-date", %{"date" => date_str}, socket) do
    date_time = from_str!(date_str)

    if Date.compare(socket.assigns.min, DateTime.to_date(date_time)) == :gt do
      {:noreply, socket}
    else
      ranges = %{
        range_start: date_time
      }

      send(self(), {:updated_reservation, ranges})

      {
        :noreply,
        socket
        |> assign(ranges)
        |> assign(:state, @initial_state)
      }
    end
  end

  defp next_month_new_date(current_date, last_row) do
    last_row_last_day = last_row |> List.last()
    last_row_last_month = last_row_last_day |> Calendar.strftime("%B")
    last_row_first_month = last_row |> List.first() |> Calendar.strftime("%B")
    current_month = Calendar.strftime(current_date, "%B")
    next_month = next_month(last_row_first_month, last_row_last_month, last_row_last_day)

    case current_date in last_row && current_month == next_month do
      true ->
        current_date

      false ->
        current_date
        |> Date.end_of_month()
        |> Date.add(1)
    end
  end

  defp next_month(last_row_first_month, last_row_last_month, last_day)
       when last_row_first_month == last_row_last_month do
    last_day
    |> Date.end_of_month()
    |> Date.add(1)
    |> Calendar.strftime("%B")
  end

  defp next_month(_, last_day_of_last_week_month, _), do: last_day_of_last_week_month

  defp new_date(%{current: %{date: current_date, week_rows: week_rows}}) do
    current_date = current_date
    first_row = week_rows |> List.first()
    last_row = week_rows |> List.last()

    case current_date in last_row do
      true ->
        first_row
        |> List.last()
        |> Date.beginning_of_month()
        |> Date.add(-1)

      false ->
        current_date
        |> Date.beginning_of_month()
        |> Date.add(-1)
    end
  end

  defp week_rows(current_date) do
    first =
      current_date
      |> Date.beginning_of_month()
      |> Date.beginning_of_week(@week_start_at)

    last =
      current_date
      |> Date.end_of_month()
      |> Date.end_of_week(@week_start_at)

    Date.range(first, last)
    |> Enum.map(& &1)
    |> Enum.chunk_every(7)
  end

  defp before_min_date?(day, min) do
    Date.compare(day, min) == :lt
  end

  defp today?(day), do: day == Date.utc_today()

  defp other_month?(day, current_date) do
    Date.beginning_of_month(day) != Date.beginning_of_month(current_date)
  end

  defp reserved_date?(_day, []), do: false

  defp reserved_date?(day, reservations) do
    dates = Enum.map(reservations, & &1.date)
    day in dates
  end

  defp locking_date?(_day, nil), do: false

  defp locking_date?(day, locking_date) do
    day == DateTime.to_date(locking_date)
  end

  defp format_date(date) do
    %{
      date: date,
      month: Calendar.strftime(date, "%B %Y"),
      week_rows: week_rows(date)
    }
  end

  defp from_str!(""), do: nil

  defp from_str!(date_time_str) when is_binary(date_time_str) do
    with {:ok, date_time, _} <- DateTime.from_iso8601(date_time_str) do
      date_time
    else
      _ -> nil
    end
  end

  defp from_str!(date_time_str), do: date_time_str
end
