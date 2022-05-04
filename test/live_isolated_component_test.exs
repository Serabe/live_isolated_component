defmodule LiveIsolatedComponentTest do
  use ExUnit.Case

  defmodule DummyEndpoint do
    use Phoenix.Controller, namespace: LiveIsolatedComponentTest

    import Plug.Conn
  end

  @endpoint DummyEndpoint

  import LiveIsolatedComponent
  import Plug.Conn
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  defmodule DisplayComponent do
    use Phoenix.LiveComponent

    def render(assigns) do
      ~H"""
      <div class="a-class">
        Hola, <%= @name %>
      </div>
      """
    end
  end

  test "greets the name" do
    {:ok, view, html} = live_isolated_component(DisplayeComponent, %{name: "Sergio"})

    assert view
           |> has_element?(".a-class")
  end
end
