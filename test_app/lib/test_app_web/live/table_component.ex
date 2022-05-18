defmodule TestAppWeb.Live.TableComponent do
  use TestAppWeb, :live_component

  def render(assigns) do
    ~H"""
    <table>
      <%= for col <- @col do %>
        <div class="col">
          <div class="content">
            <%= render_slot(col, %{es: "Hola", en: "Hello"}) %>
          </div>
          <div class="attrs">
            <%= for key <- Map.keys(col), !Enum.member?([:__slot__, :inner_block], key) do %>
              <span class="attr">
                <%= key %>: <%= col[key] %>
              </span>
            <% end %>
          </div>
        </div>
      <% end %>
    </table>
    """
  end
end
