defmodule TestAppWeb.Live.ArticleComponentTest do
  use TestAppWeb.ConnCase, async: true

  alias TestAppWeb.Live.ArticleComponent

  import LiveIsolatedComponent
  import Phoenix.LiveViewTest
  import Phoenix.LiveView.Helpers, only: [sigil_H: 2]

  test "displays static content (as sigil_H)" do
    assigns = %{}

    {:ok, view, _html} =
      render_article_with_slots(
        header: %{
          attr: 1,
          inner_block: ~H"""
          Some header
          """
        },
        inner_block: ~H"""
        Some content
        """
      )

    assert has_element?(view, "header", "Some header")
    assert has_element?(view, ".content", "Some content")
  end

  defp render_article_with_slots(slots) do
    assigns = %{}

    live_isolated_component(ArticleComponent,
      assigns: %{post: %{author: "X", summary: "ABX", tags: "Ember"}},
      slots:
        Keyword.merge(
          [
            header: ~H"""
            Some header
            """,
            inner_block: ~H"""
            Some content
            """
          ],
          slots
        )
    )
  end
end
