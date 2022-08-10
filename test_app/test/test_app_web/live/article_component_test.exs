defmodule TestAppWeb.Live.ArticleComponentTest do
  use TestAppWeb.ConnCase, async: true

  alias TestAppWeb.Live.ArticleComponent

  import LiveIsolatedComponent
  import Phoenix.LiveViewTest
  import Phoenix.LiveView.Helpers, only: [sigil_H: 2]

  test "displays static content (as sigil_H) both directly or as part of a map" do
    {:ok, view, _html} =
      render_article_with_slots(
        header:
          slot do
            ~H"""
            Some header
            """
          end,
        inner_block:
          slot do
            ~H"""
            Some content
            """
          end
      )

    assert has_element?(view, "header .content", "Some header")
    assert has_element?(view, "div.content", "Some content")
  end

  test "if a function of arity 1, receives assigns" do
    {:ok, view, _html} =
      render_article_with_slots(
        header:
          slot do
            ~H"""
            Author: <%= @post.author %>
            """
          end,
        inner_block:
          slot do
            ~H"""
            Tags: <%= @post.tags %>
            """
          end
      )

    assert has_element?(view, "header .content", "Author: X")
    assert has_element?(view, "div.content", "Tags: Ember")
  end

  test "if a function of arity 2, it is just passed to LV" do
    {:ok, view, _html} =
      render_article_with_slots(
        header:
          slot do
            ~H"""
            Some header
            """
          end,
        inner_block:
          slot do
            ~H"""
            Some content
            """
          end
      )

    assert has_element?(view, "header .content", "Some header")
    assert has_element?(view, "div.content", "Some content")
  end

  test "attributes can be passed to the slot" do
    {:ok, view, _html} =
      render_article_with_slots(
        header:
          slot(es: "Hola", en: "Hello") do
            ~H"""
            Some header
            """
          end,
        inner_block:
          slot do
            ~H"""
            Some content
            """
          end
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
