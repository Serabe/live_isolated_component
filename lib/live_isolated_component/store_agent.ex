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

  def get_slots(pid, assigns) do
    pid
    |> get_data(:slots, %{})
    |> Map.new(fn {slot_name, slot_descs} ->
      {slot_name,
       Enum.map(slot_descs, fn desc ->
         Map.merge(desc, %{inner_block: desc.inner_block.(assigns)})
       end)}
    end)
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

  defp normalize_option({:slots, nil}), do: {:slots, %{}}
  defp normalize_option({:slots, slots}), do: {:slots, normalize_slots(slots)}

  defp normalize_option(other), do: other

  defp normalize_slot({slot_name, descriptor}) when is_list(descriptor) do
    {slot_name, Enum.map(descriptor, &normalize_slot({slot_name, &1}))}
  end

  defp normalize_slot({slot_name, descriptor}) when is_function(descriptor, 1) do
    {slot_name, [%{__slot__: slot_name, inner_block: normalize_slot_inner_block(descriptor)}]}
  end

  defp normalize_slot({slot_name, %{inner_block: inner_block} = attrs}) do
    {slot_name,
     [
       Map.merge(attrs, %{
         __slot__: slot_name,
         inner_block: normalize_slot_inner_block(inner_block)
       })
     ]}
  end

  defp normalize_slot({slot_name, other}) do
    {slot_name, [%{__slot__: slot_name, inner_block: normalize_slot_inner_block(other)}]}
  end

  defp normalize_slot_inner_block(fun) when is_function(fun, 1) do
    fn assigns ->
      result = fun.(assigns)

      cond do
        is_function(result, 2) -> result
        true -> fn _a, _b -> result end
      end
    end
  end

  defp normalize_slot_inner_block(fun) when is_function(fun, 2) do
    fn _assigns -> fun end
  end

  defp normalize_slot_inner_block(other) do
    fn _assigns ->
      fn _a, _b ->
        other
      end
    end
  end

  defp normalize_slots(slots) when is_map(slots) do
    Map.new(slots, &normalize_slot/1)
  end

  defp normalize_slots(slots), do: slots |> Enum.into(%{}) |> normalize_slots()

  def as_slot(content) when is_function(content), do: content
  def as_slot(content), do: fn _assigns -> content end
end
