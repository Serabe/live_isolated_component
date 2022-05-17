defmodule TestAppWeb.Live.ArticleComponentTest do
  use TestAppWeb.ConnCase, async: true

  alias TestAppWeb.Live.ArticleComponent

  import LiveIsolatedComponent
  import Phoenix.LiveViewTest
  import Phoenix.LiveView.Helpers, only: [sigil_H: 2]

  test "displays static content (as sigil_H) both directly or as part of a map" do
    assigns = %{}

    {:ok, view, _html} =
      render_article_with_slots(
        header: %{
          inner_block: ~H"""
          Some header
          """
        },
        inner_block: ~H"""
        Some content
        """
      )

    assert has_element?(view, "header .content", "Some header")
    assert has_element?(view, "div.content", "Some content")
  end

  test "if a function of arity 1, receives assigns" do
    {:ok, view, _html} =
      render_article_with_slots(
        header: %{
          inner_block: fn assigns ->
            ~H"""
            Author: <%= @post.author %>
            """
          end
        },
        inner_block: fn assigns ->
          ~H"""
          Tags: <%= @post.tags %>
          """
        end
      )

    assert has_element?(view, "header .content", "Author: X")
    assert has_element?(view, "div.content", "Tags: Ember")
  end

  test "if a function of arity 2, it is just passed to LV" do
    assigns = %{}

    {:ok, view, _html} =
      render_article_with_slots(
        header: %{
          inner_block: fn _a, _b ->
            ~H"""
            Some header
            """
          end
        },
        inner_block: fn _a, _b ->
          ~H"""
          Some content
          """
        end
      )

    assert has_element?(view, "header .content", "Some header")
    assert has_element?(view, "div.content", "Some content")
  end

  test "attributes can be passed to the slot" do
    assigns = %{}

    {:ok, view, _html} =
      render_article_with_slots(
        header: %{
          es: "Hola",
          en: "Hello",
          inner_block: ~H"""
          Some header
          """
        },
        inner_block: ~H"""
        Some content
        """
      )

    assert has_element?(view, "header .attr", "en: Hello")
    assert has_element?(view, "header .attr", "es: Hola")
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
