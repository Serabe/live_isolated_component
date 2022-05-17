defmodule TestAppWeb.Live.ArticleComponent do
  use TestAppWeb, :live_component

  def render(assigns) do
    ~H"""
    <article>
      <header>
        <%= render_slot(@header, %{title: "Article by #{@post.author}"}) %>
      </header>
      <div class="content">
        <%= render_slot(@inner_block, %{summary: @post.summary}) %>
      </div>
    </article>
    """
  end
end
