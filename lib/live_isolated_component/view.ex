defmodule LiveIsolatedComponent.View do
  @moduledoc false
  use Phoenix.LiveView

  alias LiveIsolatedComponent.StoreAgent
  alias LiveIsolatedComponent.Utils
  alias LiveIsolatedComponent.ViewUtils
  alias Phoenix.LiveView.TagEngine

  def mount(params, session, socket), do: ViewUtils.mount(params, session, socket)

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
end
