defmodule TestAppWeb.Live.RemoteButtonComponentTest do
  use TestAppWeb.ConnCase, async: true

  alias TestAppWeb.Live.RemoteButtonComponent

  import LiveIsolatedComponent
  import Phoenix.LiveViewTest

  test "calls the function correctly" do
    {:ok, view, _html} =
      live_isolated_component(RemoteButtonComponent, %{remote_call: fn -> "Red" end})

    view
    |> element("button")
    |> render_click()

    assert has_element?(view, "button", "My Red")
  end

  test "function can be updated" do
    {:ok, view, _html} =
      live_isolated_component(RemoteButtonComponent, %{remote_call: fn -> "Red" end})

    view
    |> element("button")
    |> render_click()

    assert has_element?(view, "button", "My Red")

    live_assign(view, :remote_call, fn -> "Blue" end)

    view
    |> element("button")
    |> render_click()

    assert has_element?(view, "button", "My Blue")
  end
end
