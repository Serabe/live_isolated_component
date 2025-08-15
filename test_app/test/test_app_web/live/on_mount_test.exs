defmodule TestAppWeb.Live.OnMountTest do
  use TestAppWeb.ConnCase, async: true

  import LiveIsolatedComponent
  import Phoenix.Component, only: [sigil_H: 2]
  import Phoenix.LiveViewTest

  defmodule IncEvent do
    import Phoenix.Component
    import Phoenix.LiveView

    def on_mount(prop \\ :default, _params, _session, socket) do
      {:cont,
       attach_hook(socket, :inc_prop, :handle_event, fn
         "inc", _params, socket ->
           {:halt,
            update(socket, :assigns, fn assigns ->
              Map.update!(assigns, prop, &(&1 + 1))
            end)}

         _message, _params, socket ->
           {:cont, socket}
       end)}
    end
  end

  defmodule IncProperty do
    import Phoenix.Component
    import Phoenix.LiveView

    def on_mount(prop \\ :default, _params, _session, socket) do
      {:cont,
       attach_hook(socket, :inc_prop, :handle_info, fn
         :inc, socket ->
           {:halt,
            update(socket, :assigns, fn assigns ->
              Map.update!(assigns, prop, &(&1 + 1))
            end)}

         _message, socket ->
           {:cont, socket}
       end)}
    end
  end

  test "on_mount sets the plugin up in the mock view (just module)" do
    {:ok, view, _html} =
      live_isolated_component(
        fn assigns ->
          ~H[<div class="comp"><%= @default %></div>]
        end,
        assigns: %{default: 0},
        on_mount: [IncProperty]
      )

    assert view
           |> render()
           |> LazyHTML.from_fragment()
           |> LazyHTML.query(".comp")
           |> LazyHTML.text() == "0"

    send(view.pid, :inc)
    :sys.get_state(view.pid)

    assert view
           |> render()
           |> LazyHTML.from_fragment()
           |> LazyHTML.query(".comp")
           |> LazyHTML.text() == "1"
  end

  test "on_mount sets the plugin up in the mock view (tuple)" do
    {:ok, view, _html} =
      live_isolated_component(
        fn assigns ->
          ~H[<div class="comp"><%= @prop %></div>]
        end,
        assigns: %{prop: 0},
        on_mount: [{IncProperty, :prop}]
      )

    assert view
           |> render()
           |> LazyHTML.from_fragment()
           |> LazyHTML.query(".comp")
           |> LazyHTML.text() == "0"

    send(view.pid, :inc)
    :sys.get_state(view.pid)

    assert view
           |> render()
           |> LazyHTML.from_fragment()
           |> LazyHTML.query(".comp")
           |> LazyHTML.text() == "1"
  end

  test "on_mount does not hide the handle_info spy" do
    {:ok, view, _html} =
      live_isolated_component(
        fn assigns ->
          ~H[<div class="comp"><%= @default %></div>]
        end,
        assigns: %{default: 0},
        on_mount: [IncProperty]
      )

    assert view
           |> render()
           |> LazyHTML.from_fragment()
           |> LazyHTML.query(".comp")
           |> LazyHTML.text() == "0"

    send(view.pid, :inc)
    :sys.get_state(view.pid)

    assert view
           |> render()
           |> LazyHTML.from_fragment()
           |> LazyHTML.query(".comp")
           |> LazyHTML.text() == "1"

    assert_handle_info(view, :inc)
  end

  test "on_mount does not hide the handle_event spy" do
    {:ok, view, _html} =
      live_isolated_component(
        fn assigns ->
          ~H[<div class="comp"><%= @default %></div><button phx-click="inc">Inc</button>]
        end,
        assigns: %{default: 0},
        on_mount: [IncEvent]
      )

    assert view
           |> render()
           |> LazyHTML.from_fragment()
           |> LazyHTML.query(".comp")
           |> LazyHTML.text() == "0"

    view
    |> element("button")
    |> render_click()

    assert view
           |> render()
           |> LazyHTML.from_fragment()
           |> LazyHTML.query(".comp")
           |> LazyHTML.text() == "1"

    assert_handle_event(view, "inc")
  end

  test "on_mount does not break the mechanism for updating the assigns" do
    {:ok, view, _html} =
      live_isolated_component(
        fn assigns ->
          ~H[<div class="comp"><%= @default %></div>]
        end,
        assigns: %{default: 0},
        on_mount: [IncProperty]
      )

    assert view
           |> render()
           |> LazyHTML.from_fragment()
           |> LazyHTML.query(".comp")
           |> LazyHTML.text() == "0"

    live_assign(view, default: 5)

    assert view
           |> render()
           |> LazyHTML.from_fragment()
           |> LazyHTML.query(".comp")
           |> LazyHTML.text() == "5"
  end
end
