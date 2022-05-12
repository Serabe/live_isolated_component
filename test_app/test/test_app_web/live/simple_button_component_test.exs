defmodule TestAppWeb.Live.SimpleButtonComponentTest do
  use TestAppWeb.ConnCase, async: true

  alias TestAppWeb.Live.SimpleButtonComponent

  alias LiveIsolatedComponent.HandleEventSpy
  alias Phoenix.LiveView, as: LV

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

  test "executes the default impl for spy" do
    {spy, callback} =
      HandleEventSpy.new(fn _event, _params, socket ->
        {:noreply, LV.assign(socket, :description, "blue-ish")}
      end)

    {:ok, view, _html} =
      live_isolated_component(SimpleButtonComponent,
        assigns: %{on_click: :i_was_clicked, description: "red-ish"},
        handle_event: callback
      )

    assert has_element?(view, "button", "My red-ish button")

    view
    |> element("button")
    |> render_click()

    assert has_element?(view, "button", "My blue-ish button")
  end

  test "we get to spy arguments" do
    {spy, callback} = HandleEventSpy.new()

    {:ok, view, _html} =
      live_isolated_component(SimpleButtonComponent,
        assigns: %{on_click: :i_was_clicked},
        handle_event: callback
      )

    view |> element("button") |> render_click()

    assert %{arguments: {"i_was_clicked", _p, _s}} = HandleEventSpy.last_event(spy)
  end

  test "we get to spy result" do
    {spy, callback} = HandleEventSpy.new()

    {:ok, view, _html} =
      live_isolated_component(SimpleButtonComponent,
        assigns: %{on_click: :i_was_clicked},
        handle_event: callback
      )

    view |> element("button") |> render_click()

    assert %{result: {:noreply, _s}} = HandleEventSpy.last_event(spy)
  end
end
