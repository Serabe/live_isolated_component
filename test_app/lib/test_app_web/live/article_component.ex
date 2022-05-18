defmodule TestAppWeb.Live.ArticleComponent do
  use TestAppWeb, :live_component

  def render(assigns) do
    ~H"""
    <article>
      <header>
        <span class="content">
          <%= render_slot(@header, %{title: "Article by #{@post.author}"}) %>
        </span>
        <span class="attrs">
          <%= for header <- @header do %>
            <%= for key <- Map.keys(header), !Enum.member?([:__slot__, :inner_block], key) do %>
              <span class="attr">
                <%= key %>: <%= header[key] %>
              </span>
            <% end %>
          <% end %>
        </span>
      </header>
      <div class="content">
        <%= render_slot(@inner_block, %{summary: @post.summary}) %>
      </div>
    </article>
    """
  end
end
