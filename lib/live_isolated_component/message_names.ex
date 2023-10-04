defmodule LiveIsolatedComponent.MessageNames do
  @moduledoc false

  @doc false
  def handle_event_received_message, do: :__live_isolated_component_handle_event_received__

  @doc false
  def handle_event_result_message, do: :__live_isolated_component_handle_event_result_received__

  @doc false
  def handle_info_received_message, do: :__live_isolated_component_handle_info_received__

  @doc false
  def store_agent_key, do:  "live_isolated_component_store_agent"

  @doc false
  def updates_event, do: "live_isolated_component_update_event"
end
