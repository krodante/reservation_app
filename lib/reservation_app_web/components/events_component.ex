defmodule ReservationAppWeb.Components.EventsComponent do
  use ReservationAppWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""

    <div id="events_component">
      <%= if @events == [] do %>
        No events
      <% else %>
        <%= for event <- @events do %>
          <div>
            <strong><%= event.user_slug %></strong> set <strong><%= event.name %></strong> for <strong><%= Date.to_string(event.date) %></strong>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {
      :ok,
      socket
      |> assign(:events, [])
      |> assign(:user_slug, nil)
    }
  end

  @impl true
  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(:events, assigns.events)
      |> assign(:user_slug, assigns.user_slug)
    }
  end
end
