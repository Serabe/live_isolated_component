defmodule TestAppWeb.Live.SimpleButtonComponent do
  use TestAppWeb, :live_component

  def render(assigns) do
    ~H"""
    <button phx-click={@on_click}>
      My button
    </button>
    """
  end
end
