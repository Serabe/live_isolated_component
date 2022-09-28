defmodule TestAppWeb.Live.FunctionComponentTest do
  use TestAppWeb.ConnCase, async: true

  import LiveIsolatedComponent
  import Phoenix.LiveViewTest
  import Phoenix.LiveView, only: [assign_new: 3]
  import Phoenix.LiveView.Helpers, only: [render_slot: 1, sigil_H: 2]

  def fn_component(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "class" end)
      |> assign_new(:inner_block, fn -> [] end)

    ~H"""
    <button class={@class} phx-click="event" id={@id}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  test "id by default is some-unique-id" do
    {:ok, view, _html} = live_isolated_component(&fn_component/1)

    assert has_element?(view, "#some-unique-id")
  end

  test "id can be overriden" do
    id = "some-other-id"
    {:ok, view, _html} = live_isolated_component(&fn_component/1, assigns: %{id: id})

    assert has_element?(view, "##{id}")
  end

  test "displays slots" do
    {:ok, view, _html} =
      live_isolated_component(&fn_component/1,
        slots:
          slot do
            ~H[Hello]
          end
      )

    assert has_element?(view, "button", "Hello")
  end

  test "handle event" do
    {:ok, view, _html} =
      live_isolated_component(&fn_component/1,
        slots:
          slot do
            ~H[Hello]
          end
      )

    view
    |> element("button")
    |> render_click()

    assert_handle_event(view, "event")
  end

  test "assigns" do
    {:ok, view, _html} =
      live_isolated_component(&fn_component/1,
        assigns: %{class: "kallax"},
        slots:
          slot do
            ~H[Hello]
          end
      )

    assert has_element?(view, "button.kallax")
  end

  test "gets rerendered when assigns change" do
    {:ok, view, _html} =
      live_isolated_component(&fn_component/1,
        assigns: %{class: "kallax"},
        slots:
          slot do
            ~H[Hello]
          end
      )

    assert has_element?(view, "button.kallax")

    live_assign(view, :class, "billy")

    assert has_element?(view, "button.billy")
  end
end
