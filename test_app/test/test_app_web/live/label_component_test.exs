defmodule TestAppWeb.Live.LabelComponentTest do
  use TestAppWeb.ConnCase, async: true

  alias TestAppWeb.Live.LabelComponent

  import LiveIsolatedComponent
  import Phoenix.LiveViewTest
  import Phoenix.LiveView.Helpers, only: [sigil_H: 2]

  test "displays content (as sigil_H)" do
    {:ok, view, _html} =
      live_isolated_component(LabelComponent,
        assigns: %{for: "some-id"},
        slots:
          slot(assigns: assigns) do
            ~H"""
            <span class="some-content">Some content</span>
            """
          end
      )

    assert has_element?(view, "span.some-content", "Some content")
  end

  test "displays content (as fn)" do
    {:ok, view, _html} =
      live_isolated_component(LabelComponent,
        assigns: %{for: "some-id"},
        slots:
          slot(assigns: assigns) do
            ~H"""
            <span class="some-content">Some content</span>
            """
          end
      )

    assert has_element?(view, "span.some-content", "Some content")
  end

  test "gets the assigns from the LV" do
    {:ok, view, _html} =
      live_isolated_component(LabelComponent,
        assigns: %{for: "some-id"},
        slots:
          slot(assigns: assigns) do
            ~H"""
            <span class="some-content">Some content for <%= @for %></span>
            """
          end
      )

    assert has_element?(view, "span.some-content", "Some content for some-id")
  end

  test "assigns get re-rendered" do
    {:ok, view, _html} =
      live_isolated_component(LabelComponent,
        assigns: %{for: "some-id"},
        slots: [
          inner_block:
            slot(assigns: assigns) do
              ~H"""
              <span class="some-content">Some content for <%= @for %></span>
              """
            end
        ]
      )

    assert has_element?(view, "span.some-content", "Some content for some-id")

    live_assign(view, for: "some-other-id")

    assert has_element?(view, "span.some-content", "Some content for some-other-id")
  end
end
