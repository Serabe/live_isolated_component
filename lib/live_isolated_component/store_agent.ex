defmodule LiveIsolatedComponent.StoreAgent do
  @moduledoc false
  import Phoenix.LiveView.Helpers, only: [sigil_H: 2]

  def start(fun) do
    Agent.start(fn ->
      fun.() |> normalize_options()
    end)
  end

  def stop(agent, reason \\ :normal, timeout \\ :infinity) do
    Agent.stop(agent, reason, timeout)
  end

  def get_assigns(pid), do: get_data(pid, :assigns, %{})

  def get_handle_event(pid) do
    get_data(pid, :handle_event, fn _event, _params, socket -> {:noreply, socket} end)
  end

  def get_handle_info(pid) do
    get_data(pid, :handle_info, fn _event, socket -> {:noreply, socket} end)
  end

  def get_inner_block(pid) do
    get_data(pid, :inner_block, fn assigns ->
      ~H"""
      """
    end)
  end

  defp get_data(pid, key, default_value) do
    case Agent.get(pid, & &1) do
      %{^key => nil} -> default_value
      %{^key => value} -> value
      _ -> default_value
    end
  end

  defp normalize_options(opts) do
    Map.new(opts, &normalize_option/1)
  end

  defp normalize_option({:assigns, assigns}) when is_map(assigns), do: {:assigns, assigns}
  defp normalize_option({:assigns, assigns}), do: {:assigns, Enum.into(assigns, %{})}

  defp normalize_option({:inner_block, inner_block}), do: {:inner_block, as_slot(inner_block)}

  defp normalize_option(other), do: other

  def as_slot(content) when is_function(content), do: content
  def as_slot(content), do: fn _assigns -> content end
end
