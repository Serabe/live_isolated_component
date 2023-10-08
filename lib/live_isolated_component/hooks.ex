defmodule LiveIsolatedComponent.Hooks.HandleEventSpyHook do
  @moduledoc false
  import Phoenix.LiveView

  alias LiveIsolatedComponent.Utils

  def on_mount(:default, _params, _session, socket) do
    {:cont, attach_hook(socket, :lic_handle_event_spy, :handle_event, &handle_event/3)}
  end

  def handle_event(event, params, socket) do
    original_assigns = socket.assigns

    Utils.send_to_test(
      socket,
      original_assigns,
      {LiveIsolatedComponent.MessageNames.handle_event_received_message(), self(),
       {event, params}}
    )

    {:cont, socket}
  end
end

defmodule LiveIsolatedComponent.Hooks.HandleInfoSpyHook do
  @moduledoc false
  import Phoenix.LiveView

  alias LiveIsolatedComponent.Utils

  def on_mount(:default, _params, _session, socket) do
    {:cont, attach_hook(socket, :lic_handle_info_spy, :handle_info, &handle_info/2)}
  end

  def handle_info(event, socket) do
    original_assigns = socket.assigns

    Utils.send_to_test(
      socket,
      original_assigns,
      {LiveIsolatedComponent.MessageNames.handle_info_received_message(), self(), event}
    )

    {:cont, socket}
  end
end

defmodule LiveIsolatedComponent.Hooks.AssignsUpdateSpyHook do
  @moduledoc false
  import Phoenix.LiveView

  alias LiveIsolatedComponent.StoreAgent
  alias LiveIsolatedComponent.Utils

  @event_name LiveIsolatedComponent.MessageNames.updates_event()

  def on_mount(:default, _params, _session, socket) do
    {:cont, attach_hook(socket, :lic_assings_update, :handle_info, &handle_info/2)}
  end

  def handle_info({@event_name, pid}, socket) do
    values = Agent.get(pid, & &1)
    Agent.stop(pid)

    socket
    |> Utils.store_agent_pid()
    |> StoreAgent.update(values)

    {:halt, Utils.update_socket_from_store_agent(socket)}
  end

  def handle_info(_message, socket), do: {:cont, socket}
end
