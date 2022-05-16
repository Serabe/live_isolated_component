defmodule TestAppWeb.Live.ComplexButtonComponent do
  use TestAppWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign_new(:count, fn -> 0 end)
     |> assign_new(:description, fn -> "beautiful" end)
     |> assign(assigns)}
  end

  def render(assigns) do
    ~H"""
    <button phx-click="clicked" phx-target={@myself}>
      My <%= @description %> button
    </button>
    """
  end

  def handle_event("clicked", _params, socket) do
    event = socket.assigns.on_click || "on_click"

    socket = update(socket, :count, &(&1 + 1))

    send(self(), {event, socket.assigns.count})

    {:noreply, socket}
  end
end
