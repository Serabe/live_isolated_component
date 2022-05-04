defmodule TestAppWeb.Live.GreetingsComponentTest do
  use TestAppWeb.ConnCase, async: true

  alias TestAppWeb.Live.GreetingsComponent

  import LiveIsolatedComponent
  import Phoenix.LiveViewTest

  test "displays name" do
    {:ok, view, html} = live_isolated_component(GreetingsComponent, %{name: "Sergio"})

    assert has_element?(view, ".a-class")

    assert view
           |> element(".a-class")
           |> render()
           |> Floki.parse_fragment!()
           |> Floki.text()
           |> String.trim() ==
             "Hello, Sergio"
  end
end
