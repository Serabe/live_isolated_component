defmodule LiveIsolatedComponent.Utils do
  import Phoenix.Component

  alias LiveIsolatedComponent.StoreAgent

  def store_agent_pid(%{assigns: %{store_agent: pid}}) when is_pid(pid),
    do: pid

  def update_socket_from_store_agent(socket) do
    agent = store_agent_pid(socket)

    component = StoreAgent.get_component(agent)

    socket
    |> assign(:assigns, StoreAgent.get_assigns(agent))
    |> assign(:component, component)
    |> assign(:slots, StoreAgent.get_slots(agent))
  end

  def denormalize_socket(socket, original_assigns) do
    socket
    |> Map.put(:assigns, original_assigns)
    |> assign(:assigns, socket.assigns)
  end

  def normalize_socket(socket, original_assigns) do
    assign_like_structure = Map.put(original_assigns.assigns, :__changed__, %{})
    Map.put(socket, :assigns, assign_like_structure)
  end

  def send_to_test(socket, original_assigns, message) do
    socket
    |> denormalize_socket(original_assigns)
    |> store_agent_pid()
    |> StoreAgent.send_to_test(message)
  end
end
