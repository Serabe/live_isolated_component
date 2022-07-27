defmodule TestAppWeb.Live.FunctionComponentTest do
  use TestAppWeb.ConnCase, async: true

  import LiveIsolatedComponent
  import Phoenix.LiveViewTest
  import Phoenix.LiveView.Helpers, only: [render_slot: 1, sigil_H: 2]

  def fn_component(assigns) do
    assigns =
      Map.merge(
        %{
          class: "class",
          inner_block: fn -> [] end
        },
        assigns
      )

    ~H"""
    <button class={@class} phx-click="event">
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  test "displays slots" do
    assigns = %{}

    {:ok, view, _html} =
      live_isolated_component(&fn_component/1,
        slots: [
          inner_block: ~H"""
            Hello
          """
        ]
      )

    assert has_element?(view, "button", "Hello")
  end

  test "handle event" do
    assigns = %{}

    {:ok, view, _html} =
      live_isolated_component(&fn_component/1,
        slots: [
          inner_block: ~H"""
            Hello
          """
        ]
      )

    view
    |> element("button")
    |> render_click()

    assert_handle_event(view, "event")
  end

  test "assigns" do
    assigns = %{}

    {:ok, view, _html} =
      live_isolated_component(&fn_component/1,
        assigns: %{class: "kallax"},
        slots: [
          inner_block: ~H"""
            Hello
          """
        ]
      )

    assert has_element?(view, "button.kallax")
  end

  test "gets rerendered when assigns change" do
    assigns = %{}

    {:ok, view, _html} =
      live_isolated_component(&fn_component/1,
        assigns: %{class: "kallax"},
        slots: [
          inner_block: ~H"""
            Hello
          """
        ]
      )

    assert has_element?(view, "button.kallax")

    live_assign(view, :class, "billy")

    assert has_element?(view, "button.billy")
  end
end
