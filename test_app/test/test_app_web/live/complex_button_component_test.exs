defmodule TestAppWeb.Live.ComplexButtonComponentTest do
  use TestAppWeb.ConnCase, async: true

  alias TestAppWeb.Live.ComplexButtonComponent

  alias LiveIsolatedComponent.HandleInfoSpy

  import LiveIsolatedComponent
  import Phoenix.LiveViewTest

  test "sends a @on_click info event" do
    {spy, callback} = HandleInfoSpy.new()

    {:ok, view, _html} =
      live_isolated_component(ComplexButtonComponent,
        assigns: %{on_click: :i_was_clicked},
        handle_info: callback
      )

    view |> element("button") |> render_click()

    assert %{arguments: {{:i_was_clicked, 1}, _s}} = HandleInfoSpy.last_event(spy)

    view |> element("button") |> render_click()

    assert %{arguments: {{:i_was_clicked, 2}, _s}} = HandleInfoSpy.last_event(spy)
  end
end
