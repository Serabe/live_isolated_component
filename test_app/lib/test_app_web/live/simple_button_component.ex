defmodule TestAppWeb.Live.SimpleButtonComponent do
  use TestAppWeb, :live_component

  def update(assigns, socket) do
    {:ok, socket |> assign(:description, "beautiful") |> assign(assigns)}
  end

  def render(assigns) do
    ~H"""
    <button phx-click={@on_click}>
      My <%= @description %> button
    </button>
    """
  end
end
