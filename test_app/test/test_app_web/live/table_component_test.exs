defmodule TestAppWeb.Live.TableComponentTest do
  use TestAppWeb.ConnCase, async: true

  alias TestAppWeb.Live.TableComponent

  import LiveIsolatedComponent
  import Phoenix.LiveViewTest
  import Phoenix.LiveView.Helpers, only: [sigil_H: 2]

  test "displays several slots" do
    assigns = %{}

    {:ok, view, _html} =
      render_table_with_slots(
        col: [
          ~H"""
          One
          """,
          %{
          inner_block: ~H"""
          Two
          """
          },
          fn assigns ->
            ~H"""
            <%= @key %>
            """
          end,
          fn _changed, assigns ->
            ~H"""
            <%= @es %> <%= @en %>
            """
          end,
          fn view_assigns ->
            fn _changed, arguments ->
              assigns = Map.merge(view_assigns, arguments)
              ~H"""
              <%= @es %> <%= @key %> <%= @en %>
              """
            end
          end
        ]
      )

    # Rendered statically and passed directly
    assert has_element?(view, ".col .content", "One")
    # Rendered statically and passed as inner_block in a map
    assert has_element?(view, ".col .content", "Two")
    # Rendered through an assigns
    assert has_element?(view, ".col .content", "value")
    # Rendered through arguments
    assert has_element?(view, ".col .content", "Hola Hello")
    # Rendered with assigns and arguments
    assert has_element?(view, ".col .content", "Hola value Hello")
  end

  defp render_table_with_slots(slots) do
    live_isolated_component(TableComponent,
      assigns: %{key: "value"},
      slots: slots
    )
  end
end
