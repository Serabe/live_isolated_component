defmodule TestAppWeb.Live.SimpleButtonComponentTest do
  use TestAppWeb.ConnCase, async: true

  alias TestAppWeb.Live.SimpleButtonComponent

  alias LiveIsolatedComponent.Spy
  alias Phoenix.LiveView, as: LV

  import LiveIsolatedComponent
  import Phoenix.LiveViewTest

  test "sends a @on_click event" do
    handle_event_spy = Spy.handle_event()

    {:ok, view, _html} =
      live_isolated_component(SimpleButtonComponent,
        assigns: %{on_click: :i_was_clicked},
        handle_event: handle_event_spy.callback
      )

    view
    |> element("button")
    |> render_click()

    assert Spy.any_event_received?(handle_event_spy)
  end

  test "executes the default impl for spy" do
    handle_event_spy =
      Spy.handle_event(fn _event, _params, socket ->
        {:noreply, LV.assign(socket, :description, "blue-ish")}
      end)

    {:ok, view, _html} =
      live_isolated_component(SimpleButtonComponent,
        assigns: %{on_click: :i_was_clicked, description: "red-ish"},
        handle_event: handle_event_spy.callback
      )

    assert has_element?(view, "button", "My red-ish button")

    view
    |> element("button")
    |> render_click()

    assert has_element?(view, "button", "My blue-ish button")
    assert Spy.any_event_received?(handle_event_spy)
  end

  test "we get to spy arguments" do
    handle_event_spy = Spy.handle_event()

    {:ok, view, _html} =
      live_isolated_component(SimpleButtonComponent,
        assigns: %{on_click: :i_was_clicked},
        handle_event: handle_event_spy.callback
      )

    view |> element("button") |> render_click()

    assert %{arguments: {"i_was_clicked", _p, _s}} = Spy.last_event(handle_event_spy)
  end

  test "we get to spy result" do
    handle_event_spy = Spy.handle_event()

    {:ok, view, _html} =
      live_isolated_component(SimpleButtonComponent,
        assigns: %{on_click: :i_was_clicked},
        handle_event: handle_event_spy.callback
      )

    view |> element("button") |> render_click()

    assert %{result: {:noreply, _s}} = Spy.last_event(handle_event_spy)
  end
end
