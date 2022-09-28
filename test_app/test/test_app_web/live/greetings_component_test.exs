defmodule TestAppWeb.Live.GreetingsComponentTest do
  use TestAppWeb.ConnCase, async: true

  alias TestAppWeb.Live.GreetingsComponent

  import LiveIsolatedComponent
  import Phoenix.LiveViewTest

  test "displays name (keywords)" do
    {:ok, view, _html} = live_isolated_component(GreetingsComponent, assigns: %{name: "Sergio"})

    assert_text(view, "Hello, Sergio")
  end

  test "displays name (map)" do
    {:ok, view, _html} = live_isolated_component(GreetingsComponent, %{name: "Sergio"})

    assert_text(view, "Hello, Sergio")
  end

  test "name can be changed via live_assign/3" do
    {:ok, view, _html} = live_isolated_component(GreetingsComponent, assigns: %{name: "Sergio"})

    assert_text(view, "Hello, Sergio")

    live_assign(view, :name, "Fran")

    assert_text(view, "Hello, Fran")
  end

  test "name can be changed via live_assign/2 (map)" do
    {:ok, view, _html} = live_isolated_component(GreetingsComponent, assigns: %{name: "Sergio"})

    assert_text(view, "Hello, Sergio")

    live_assign(view, %{name: "Fran"})

    assert_text(view, "Hello, Fran")
  end

  test "name can be changed via live_assign/2 (keywords)" do
    {:ok, view, _html} = live_isolated_component(GreetingsComponent, assigns: %{name: "Sergio"})

    assert_text(view, "Hello, Sergio")

    live_assign(view, name: "Fran")

    assert_text(view, "Hello, Fran")
  end

  test "id by default is some-uniqe-id" do
    {:ok, view, _html} = live_isolated_component(GreetingsComponent, assigns: %{name: "Sergio"})

    assert has_element?(view, "#some-unique-id")
  end

  test "id can be overriden" do
    id = "some-strange-id"

    {:ok, view, _html} =
      live_isolated_component(GreetingsComponent, assigns: %{name: "Sergio", id: id})

    assert has_element?(view, "##{id}")
  end

  test "live_assign keeps old values" do
    id = "some-strange-id"

    {:ok, view, _html} =
      live_isolated_component(GreetingsComponent, assigns: %{name: "Sergio", id: id})

    assert has_element?(view, "##{id}")
    assert_text(view, "Hello, Sergio")

    live_assign(view, name: "Fran")

    assert has_element?(view, "##{id}")
    assert_text(view, "Hello, Fran")
  end

  defp assert_text(view, text) do
    assert view
           |> element(".a-class")
           |> render()
           |> Floki.parse_fragment!()
           |> Floki.text()
           |> String.trim() ==
             text
  end
end
