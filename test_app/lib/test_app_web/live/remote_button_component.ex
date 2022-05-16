defmodule TestAppWeb.Live.RemoteButtonComponent do
  use TestAppWeb, :live_component

  def mount(socket) do
    {:ok, assign(socket, :description, "")}
  end

  def render(assigns) do
    ~H"""
    <button phx-click="clicked" phx-target={@myself}>
      My <%= @description %>
    </button>
    """
  end

  def handle_event("clicked", _params, socket) do
    {:noreply, assign(socket, :description, socket.assigns.remote_call.())}
  end
end
