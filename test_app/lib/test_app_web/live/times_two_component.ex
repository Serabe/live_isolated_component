defmodule TestAppWeb.Live.TimesTwoComponent do
  use TestAppWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <%= render_slot @inner_block, 2 * @value %>
    </div>
    """
  end
end
