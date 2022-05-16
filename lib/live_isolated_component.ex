defmodule LiveIsolatedComponent do
  @moduledoc """
  Functions for testing LiveView stateful components in isolation easily.
  """

  import Phoenix.ConnTest, only: [build_conn: 0]
  import Phoenix.LiveViewTest, only: [live_isolated: 3, render: 1]

  alias LiveIsolatedComponent.StoreAgent

  @assign_updates_event "live_isolated_component_update_assigns_event"
  @module_key "live_isolated_component_module"
  @store_agent_key "live_isolated_component_store_agent"

  defmodule View do
    @moduledoc false

    use Phoenix.LiveView

    @assign_updates_event "live_isolated_component_update_assigns_event"
    @module_key "live_isolated_component_module"
    @store_agent_key "live_isolated_component_store_agent"

    def mount(_params, session, socket) do
      socket =
        socket
        |> assign(:store_agent, session[@store_agent_key])
        |> assign(:module, session[@module_key])
        |> then(fn socket ->
          assign(socket, :assigns, socket |> store_agent_pid() |> StoreAgent.get_assigns())
        end)

      {:ok, socket}
    end

    def render(assigns) do
      ~H"""
        <.live_component
          id="some-unique-id"
          module={@module}
          {@assigns}
          >
          <%= StoreAgent.get_inner_block(@store_agent).(@assigns) %>
        </.live_component>
      """
    end

    def handle_event(event, params, socket) do
      handle_event = socket |> store_agent_pid() |> StoreAgent.get_handle_event()
      original_assigns = socket.assigns

      case handle_event.(event, params, normalize_socket(socket, original_assigns)) do
        {:noreply, socket} ->
          {:noreply, denormalize_socket(socket, original_assigns)}

        {:reply, map, socket} ->
          {:reply, map, denormalize_socket(socket, original_assigns)}
      end
    end

    def handle_info({@assign_updates_event, pid}, socket) do
      values = Agent.get(pid, & &1)
      Agent.stop(pid)
      {:noreply, assign(socket, :assigns, values)}
    end

    def handle_info(event, socket) do
      handle_info = socket |> store_agent_pid() |> StoreAgent.get_handle_info()
      original_assigns = socket.assigns

      {:noreply, socket} = handle_info.(event, normalize_socket(socket, original_assigns))

      {:noreply, denormalize_socket(socket, original_assigns)}
    end

    defp store_agent_pid(%{assigns: %{store_agent: pid}}) when is_pid(pid), do: pid

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
    # We need to use agents because fns are not serializable.
    # The LV will stop this agent
    {:ok, pid} = Agent.start(fn -> Enum.into(keyword_or_map, %{}) end)

    send(view.pid, {@assign_updates_event, pid})

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
    - `:content` accepts either the result of `sigil_H` or a function accepting an assigns and returning a hex template.
    - `:handle_event` accepts a handler for the `handle_event` callback in the LiveView.
    - `:handle_info` acceptas a handler for the `handle_info` callback in the LiveView.
  """
  defmacro live_isolated_component(module, opts \\ %{}) do
    quote do
      opts = if is_map(unquote(opts)), do: [assigns: unquote(opts)], else: unquote(opts)

      # We need to use agents because fns are not serializable.
      {:ok, store_agent} =
        StoreAgent.start(fn ->
          %{
            assigns: Keyword.get(opts, :assigns, %{}),
            inner_block: Keyword.get(opts, :content),
            handle_event: Keyword.get(opts, :handle_event),
            handle_info: Keyword.get(opts, :handle_info)
          }
        end)

      live_isolated(build_conn(), View,
        session: %{
          unquote(@module_key) => unquote(module),
          unquote(@store_agent_key) => store_agent
        }
      )
    end
  end
end
