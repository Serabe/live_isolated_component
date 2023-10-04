defmodule LiveIsolatedComponent.View do
  @moduledoc false
  use Phoenix.LiveView

  alias LiveIsolatedComponent.Hooks
  alias LiveIsolatedComponent.StoreAgent
  alias LiveIsolatedComponent.Utils
  alias Phoenix.LiveView.TagEngine

  def mount(params, session, socket) do
    socket =
      socket
      |> assign(:store_agent, session[LiveIsolatedComponent.MessageNames.store_agent_key()])
      |> run_on_mount(params, session)
      |> Utils.update_socket_from_store_agent()

    {:ok, socket}
  end

  def render(%{component: component, store_agent: agent, assigns: component_assigns} = _assigns)
      when is_function(component) do
    TagEngine.component(
      component,
      Map.merge(
        component_assigns,
        StoreAgent.get_slots(agent, component_assigns)
      ),
      {__ENV__.module, __ENV__.function, __ENV__.file, __ENV__.line}
    )
  end

  def render(assigns) do
    new_inner_assigns = Map.put_new(assigns.assigns, :id, "some-unique-id")

    assigns = Map.put(assigns, :assigns, new_inner_assigns)

    ~H"""
      <.live_component
        id={@assigns.id}
        module={@component}
        {@assigns}
        {@slots}
        />
    """
  end

  def handle_info(event, socket) do
    handle_info = socket |> Utils.store_agent_pid() |> StoreAgent.get_handle_info()
    original_assigns = socket.assigns

    {:noreply, socket} = handle_info.(event, Utils.normalize_socket(socket, original_assigns))

    {:noreply, Utils.denormalize_socket(socket, original_assigns)}
  end

  def handle_event(event, params, socket) do
    handle_event = socket |> Utils.store_agent_pid() |> StoreAgent.get_handle_event()
    original_assigns = socket.assigns

    result = handle_event.(event, params, Utils.normalize_socket(socket, original_assigns))

    Utils.send_to_test(
      socket,
      original_assigns,
      {LiveIsolatedComponent.MessageNames.handle_event_result_message(), self(),
       handle_event_result_as_event_param(result)}
    )

    denormalize_result(result, original_assigns)
  end

  defp handle_event_result_as_event_param({:noreply, _socket}), do: :noreply
  defp handle_event_result_as_event_param({:reply, map, _socket}), do: {:reply, map}

  defp denormalize_result({:noreply, socket}, original_assigns),
    do: {:noreply, Utils.denormalize_socket(socket, original_assigns)}

  defp denormalize_result({:reply, map, socket}, original_assigns),
    do: {:reply, map, Utils.denormalize_socket(socket, original_assigns)}

  defp run_on_mount(socket, params, session),
    do: run_on_mount(socket.assigns.store_agent, params, session, socket)

  defp run_on_mount(agent, params, session, socket) do
    agent
    |> StoreAgent.get_on_mount()
    |> add_lic_hooks()
    |> Enum.reduce(socket, &do_run_on_mount(&1, params, session, &2))
  end

  defp do_run_on_mount({module, first}, params, session, socket) do
    {:cont, socket} = module.on_mount(first, params, session, socket)
    socket
  end

  defp do_run_on_mount(module, params, session, socket),
    do: do_run_on_mount({module, :default}, params, session, socket)

  defp add_lic_hooks(list),
    do: [Hooks.HandleEventSpyHook, Hooks.HandleInfoSpyHook, Hooks.AssignsUpdateSpyHook | list]
end
