defmodule TestAppWeb.Live.LabelComponent do
  use TestAppWeb, :live_component

  def render(assigns) do
    ~H"""
    <label for={@for}>

      <%= render_slot(@inner_block) %>
    </label>
    """
  end
end
