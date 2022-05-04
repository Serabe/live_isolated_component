defmodule LiveIsolatedComponent do
  @moduledoc """
  Documentation for `LiveIsolatedComponent`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> LiveIsolatedComponent.hello()
      :world

  """

  import Phoenix.ConnTest, only: [build_conn: 0]
  import Phoenix.LiveViewTest, only: [live_isolated: 3]

  @module_key "live_isolated_component_module"
  @assigns_key "live_isolated_component_assigns"

  defmodule View do
    use Phoenix.LiveView

    @module_key "live_isolated_component_module"
    @assigns_key "live_isolated_component_assigns"

    def mount(_params, session, socket) do
      socket =
        socket
        |> assign(:module, session[@module_key])
        |> assign(:assigns, session[@assigns_key])

      {:ok, socket}
    end

    def render(assigns) do
      ~H"""
        <.live_component
          id="some-unique-id"
          module={@module}
          {@assigns}
          />
      """
    end
  end

  defmacro live_isolated_component(module, assigns) do
    quote do
      live_isolated(build_conn(), View,
        session: %{
          unquote(@module_key) => unquote(module),
          unquote(@assigns_key) => unquote(assigns)
        }
      )
    end
  end
end
