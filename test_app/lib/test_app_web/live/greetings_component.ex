defmodule TestAppWeb.Live.GreetingsComponent do
  use TestAppWeb, :live_component

  def render(assigns) do
    ~H"""
      <div class="a-class">
        Hello, <%= @name %>
      </div>
    """
  end
end
