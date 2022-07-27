defmodule TestAppWeb.Live.SimpleButtonComponentTest do
  use TestAppWeb.ConnCase, async: true

  alias TestAppWeb.Live.SimpleButtonComponent

  alias Phoenix.LiveView, as: LV

  import LiveIsolatedComponent
  import Phoenix.LiveViewTest

  test "sends a @on_click event" do
    {:ok, view, _html} =
      live_isolated_component(SimpleButtonComponent,
        assigns: %{on_click: :i_was_clicked}
      )

    view
    |> element("button")
    |> render_click()

    assert_handle_event(view, "i_was_clicked")
  end

  test "executes the default impl for handle_event callback" do
    handle_event = fn _event, _params, socket ->
      {:noreply, LV.assign(socket, :description, "blue-ish")}
    end

    {:ok, view, _html} =
      live_isolated_component(SimpleButtonComponent,
        assigns: %{on_click: :i_was_clicked, description: "red-ish"},
        handle_event: handle_event
      )

    assert has_element?(view, "button", "My red-ish button")

    view
    |> element("button")
    |> render_click()

    assert has_element?(view, "button", "My blue-ish button")

    assert_handle_event(view)
  end

  test "params and socket are received in the message" do
    {:ok, view, _html} =
      live_isolated_component(SimpleButtonComponent,
        assigns: %{on_click: :i_was_clicked}
      )

    view |> element("button") |> render_click()

    assert_handle_event(view, "i_was_clicked")
  end

  test "we get to spy result" do
    {:ok, view, _html} =
      live_isolated_component(SimpleButtonComponent,
        assigns: %{on_click: :i_was_clicked}
      )

    view |> element("button") |> render_click()

    assert_return_handle_event_message(view, :noreply)
  end
end
