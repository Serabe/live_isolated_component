defmodule TestAppWeb.Live.SimpleButtonComponentTest do
  use TestAppWeb.ConnCase, async: true

  alias TestAppWeb.Live.SimpleButtonComponent

  alias LiveIsolatedComponent.HandleEventSpy

  import LiveIsolatedComponent
  import Phoenix.LiveViewTest

  test "sends a @on_click event" do
    {spy, callback} = HandleEventSpy.new()

    {:ok, view, _html} =
      live_isolated_component(SimpleButtonComponent,
        assigns: %{on_click: :i_was_clicked},
        handle_event: callback
      )

    view
    |> element("button")
    |> render_click()

    assert HandleEventSpy.received_anything?(spy)
  end
end
