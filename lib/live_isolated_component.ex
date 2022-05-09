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
  import Phoenix.LiveViewTest, only: [live_isolated: 3, render: 1]

  @module_key "live_isolated_component_module"
  @assigns_key "live_isolated_component_assigns"
  @assign_updates_event "live_isolated_component_update_assigns_event"

  defmodule View do
    use Phoenix.LiveView

    @module_key "live_isolated_component_module"
    @assigns_key "live_isolated_component_assigns"
    @assign_updates_event "live_isolated_component_update_assigns_event"

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

    def handle_info({@assign_updates_event, keyword_or_map}, socket) do
      {:noreply, component_assign(socket, keyword_or_map)}
    end

    defp component_assign(socket, map) when is_map(map) do
      update(socket, :assigns, &Map.merge(&1, map))
    end

    defp component_assign(socket, other_enum) do
      component_assign(socket, Enum.into(other_enum, %{}))
    end
  end

  def live_assign(view, keyword_or_map) do
    send(view.pid, {@assign_updates_event, keyword_or_map})

    render(view)

    view
  end

  def live_assign(view, key, value) do
    live_assign(view, %{key => value})
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
