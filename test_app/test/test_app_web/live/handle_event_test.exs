defmodule TestAppWeb.Live.SimpleButtonComponentTest do
  use TestAppWeb.ConnCase, async: true

  alias Phoenix.LiveView, as: LV
  alias TestAppWeb.Live.SimpleButtonComponent

  import LiveIsolatedComponent
  import Phoenix.LiveView.Helpers, only: [sigil_H: 2]
  import Phoenix.LiveViewTest

  test "checks a specific event was sent" do
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

    assert_handle_event_return(view, :noreply)
  end

  test "check that an event was not sent" do
    {:ok, view, _html} =
      live_isolated_component(&button/1,
        assigns: %{
          on_click: "event_name",
          value: 5
        }
      )

    view |> element("button") |> render_click()

    refute_handle_event(view, "some_other_event")
    assert_handle_event(view, "event_name")
  end

  test "check that an event was not sent with a specific param" do
    {:ok, view, _html} =
      live_isolated_component(&button/1,
        assigns: %{
          on_click: "event_name",
          value: 5
        }
      )

    view |> element("button") |> render_click()

    refute_handle_event(view, "event_name", %{"value" => "1"})
    assert_handle_event(view, "event_name", %{"value" => "5"})
  end

  test "check that an event was sent with a specific param" do
    {:ok, view, _html} =
      live_isolated_component(&button/1,
        assigns: %{
          on_click: "event_name",
          value: 5
        }
      )

    view |> element("button") |> render_click()

    assert_handle_event(view, "event_name", %{"value" => "5"})
  end

  test "check that an event was not sent twice" do
    {:ok, view, _html} =
      live_isolated_component(&button/1,
        assigns: %{
          on_click: "event_name",
          value: 5
        }
      )

    view |> element("button") |> render_click()

    assert_handle_event(view, "event_name", %{"value" => "5"})
    refute_handle_event(view, "event_name", %{"value" => "5"})
  end

  test "assert can match part of the event" do
    {:ok, view, _html} =
      live_isolated_component(&button/1,
        assigns: %{
          on_click: "event_name",
          value: 5
        }
      )

    view |> element("button") |> render_click()

    assert_handle_event(view, _, %{"value" => "5"})
  end

  test "refute can match part of the event" do
    {:ok, view, _html} =
      live_isolated_component(&button/1,
        assigns: %{
          on_click: "event_name",
          value: 5
        }
      )

    view |> element("button") |> render_click()

    refute_handle_event(view, _, %{"value" => "6"})
  end

  defp button(assigns) do
    ~H"""
    <button phx-click={@on_click} phx-value-value={@value}>
      Click me
    </button>
    """
  end
end
