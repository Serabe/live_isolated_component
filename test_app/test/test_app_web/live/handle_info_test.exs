defmodule TestAppWeb.Live.HandleInfoTest do
  use TestAppWeb.ConnCase, async: true

  alias TestAppWeb.Live.ComplexButtonComponent

  alias Phoenix.LiveView, as: LV

  import LiveIsolatedComponent
  import Phoenix.LiveViewTest

  test "can check event name" do
    {:ok, view, _html} =
      live_isolated_component(ComplexButtonComponent,
        assigns: %{on_click: :i_was_clicked}
      )

    view |> element("button") |> render_click()

    assert_handle_info(view, {:i_was_clicked, 1})

    view |> element("button") |> render_click()

    assert_handle_info(view, {:i_was_clicked, 2})
  end

  test "can check any event is received" do
    {:ok, view, _html} =
      live_isolated_component(ComplexButtonComponent,
        assigns: %{on_click: :i_was_clicked}
      )

    view |> element("button") |> render_click()

    assert_handle_info(view)
  end

  test "default impl for handle_info's callback" do
    {:ok, view, _html} =
      live_isolated_component(ComplexButtonComponent,
        assigns: %{on_click: :i_was_clicked},
        handle_info: fn {:i_was_clicked, count}, socket ->
          {:noreply, LV.assign(socket, :description, "red-ish #{count}")}
        end
      )

    view |> element("button") |> render_click()

    assert has_element?(view, "button", "My red-ish 1 button")

    view |> element("button") |> render_click()

    assert has_element?(view, "button", "My red-ish 2 button")
  end
end
