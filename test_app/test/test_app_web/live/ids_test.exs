defmodule TestAppWeb.Live.IdsTest do
  use TestAppWeb.ConnCase, async: true

  alias TestAppWeb.Live.GreetingsComponent

  import LiveIsolatedComponent
  import Phoenix.Component, only: [assign_new: 3, sigil_H: 2]
  import Phoenix.LiveViewTest

  test "passing an ID uses that ID" do
    id = "some_random_id_#{Enum.random(1..10)}"

    {:ok, view, _html} =
      live_isolated_component(GreetingsComponent, assigns: %{id: id, name: "Sergio"})

    assert has_element?(view, "##{id}")
  end

  test "stateful components have id by default" do
    assigns = %{name: "Sergio"}

    refute Map.has_key?(assigns, :id)

    {:ok, view, _html} =
      live_isolated_component(TestAppWeb.Live.GreetingsComponent, assigns: assigns)

    refute view |> render() |> Floki.find(".a-class") |> Floki.attribute("id") |> Enum.empty?()
  end

  test "function components does not have id by default" do
    assert_raise KeyError, fn ->
      live_isolated_component(fn assigns ->
        ~H[<div id={@id} />]
      end)
    end
  end

  test "GH#21 using assign_new for ids" do
    id = "some-random-id-that-is-specific-to-gh21"

    {:ok, view, _html} =
      live_isolated_component(fn assigns ->
        assigns = assign_new(assigns, :id, fn -> id end)

        ~H[<div id={@id}>Hola</div>]
      end)

    assert has_element?(view, "##{id}")
  end
end
