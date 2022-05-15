defmodule LiveIsolatedComponent do
  @moduledoc """
  Functions for testing LiveView stateful components in isolation easily.
  """

  import Phoenix.ConnTest, only: [build_conn: 0]
  import Phoenix.LiveViewTest, only: [live_isolated: 3, render: 1]

  @assigns_key "live_isolated_component_assigns"
  @assign_updates_event "live_isolated_component_update_assigns_event"
  @callbacks_agent_key "live_isolated_component_callbacks_agent"
  @module_key "live_isolated_component_module"

  defmodule View do
    use Phoenix.LiveView

    @assigns_key "live_isolated_component_assigns"
    @assign_updates_event "live_isolated_component_update_assigns_event"
    @callbacks_agent_key "live_isolated_component_callbacks_agent"
    @module_key "live_isolated_component_module"

    def mount(_params, session, socket) do
      socket =
        socket
        |> assign(:module, session[@module_key])
        |> assign(:assigns, session[@assigns_key])
        |> assign(:callbacks_agent, session[@callbacks_agent_key])

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

    def handle_event(event, params, socket) do
      handle_event = get_handle_event(socket)
      original_assigns = socket.assigns

      case handle_event.(event, params, normalize_socket(socket, original_assigns)) do
        {:noreply, socket} ->
          {:noreply, denormalize_socket(socket, original_assigns)}

        {:reply, map, socket} ->
          {:reply, map, denormalize_socket(socket, original_assigns)}
      end
    end

    def handle_info({@assign_updates_event, keyword_or_map}, socket) do
      {:noreply, component_assign(socket, keyword_or_map)}
    end

    def handle_info(event, socket) do
      handle_info = get_handle_info(socket)
      original_assigns = socket.assigns

      {:noreply, socket} = handle_info.(event, normalize_socket(socket, original_assigns))

      {:noreply, denormalize_socket(socket, original_assigns)}
    end

    defp component_assign(socket, map) when is_map(map) do
      update(socket, :assigns, &Map.merge(&1, map))
    end

    defp component_assign(socket, other_enum) do
      component_assign(socket, Enum.into(other_enum, %{}))
    end

    defp get_handle_event(%{assigns: %{callbacks_agent: agent}}) do
      case Agent.get(agent, & &1) do
        %{handle_event: nil} ->
          fn _event, _params, socket -> {:noreply, socket} end

        %{handle_event: handler} ->
          handler

        _ ->
          fn _event, _params, socket -> {:noreply, socket} end
      end
    end

    def get_handle_info(%{assigns: %{callbacks_agent: agent}}) do
      case Agent.get(agent, & &1) do
        %{handle_info: nil} ->
          fn _event, socket -> {:noreply, socket} end

        %{handle_info: handler} ->
          handler

        _ ->
          fn _event, socket -> {:noreply, socket} end
      end
    end

    defp denormalize_socket(socket, original_assigns) do
      socket
      |> Map.put(:assigns, original_assigns)
      |> assign(:assigns, socket.assigns)
    end

    defp normalize_socket(socket, original_assigns) do
      assign_like_structure = Map.put(original_assigns.assigns, :__changed__, %{})
      Map.put(socket, :assigns, assign_like_structure)
    end
  end

  @doc """
  Updates the assigns of the component.

      {:ok, view, _html} = live_isolated_component(SomeComponent, assigns: %{description: "blue"})

      live_assign(view, %{description: "red"})
  """
  def live_assign(view, keyword_or_map) do
    send(view.pid, {@assign_updates_event, keyword_or_map})

    render(view)

    view
  end

  @doc """
  Updates the key in assigns of the component.

      {:ok, view, _html} = live_isolated_component(SomeComponent, assigns: %{description: "blue"})

      live_assign(view, :description, "red")
  """
  def live_assign(view, key, value) do
    live_assign(view, %{key => value})
  end

  @doc """
  Renders the given component in isolation and live so you can tested like you would
  test any LiveView.

  It accepts the following options:
    - `:assigns` accepts a map of assigns for the component.
    - `:handle_event` accepts a handler for the `handle_event` callback in the LiveView.
    - `:handle_info` acceptas a handler for the `handle_info` callback in the LiveView.
  """
  defmacro live_isolated_component(module, opts \\ %{}) do
    quote do
      opts = if is_map(unquote(opts)), do: [assigns: unquote(opts)], else: unquote(opts)

      {:ok, callbacks_agent} =
        Agent.start_link(fn ->
          %{
            handle_event: Keyword.get(opts, :handle_event),
            handle_info: Keyword.get(opts, :handle_info)
          }
        end)

      live_isolated(build_conn(), View,
        session: %{
          unquote(@module_key) => unquote(module),
          unquote(@assigns_key) => Keyword.get(opts, :assigns, %{}),
          unquote(@callbacks_agent_key) => callbacks_agent
        }
      )
    end
  end
end
