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

  defp normalize_option({:slots, nil}), do: {:slots, %{}}
  defp normalize_option({:slots, slots}), do: {:slots, normalize_slots(slots)}

  defp normalize_option(other), do: other

  # When normalizing a slot defined multiple times (like using `<.col />` multiple times).
  defp normalize_slot({slot_name, descriptor}) when is_list(descriptor) do
    {slot_name, Enum.map(descriptor, fn desc ->
      {slot_name, desc}
      |> normalize_slot()
      |> elem(1)
      |> hd()
    end)}
  end

  # Normalized a slot defined by a function
  defp normalize_slot({slot_name, descriptor}) when is_function(descriptor) do
    {slot_name, [%{__slot__: slot_name, inner_block: normalize_slot_inner_block(descriptor)}]}
  end

  # Normalize a slot defined by a map
  defp normalize_slot({slot_name, %{inner_block: inner_block} = attrs}) do
    {slot_name,
     [
       Map.merge(attrs, %{
         __slot__: slot_name,
         inner_block: normalize_slot_inner_block(inner_block)
       })
     ]}
  end

  # In any other case...
  defp normalize_slot({slot_name, other}) do
    {slot_name, [%{__slot__: slot_name, inner_block: normalize_slot_inner_block(other)}]}
  end

  # If an inner_block is a function of arity one we assume the user
  # wants to receive the assigns from the live view
  defp normalize_slot_inner_block(fun) when is_function(fun, 1) do
    fn assigns ->
      result = fun.(assigns)

      cond do
        is_function(result, 2) -> result
        true -> fn _a, _b -> result end
      end
    end
  end

  # If an inner_block is a function of arity 2, we just wrap it
  # in an arity 1 function.
  defp normalize_slot_inner_block(fun) when is_function(fun, 2) do
    fn _assigns -> fun end
  end

  # In any other case, just wrap it in two functions.
  defp normalize_slot_inner_block(other) do
    fn _assigns ->
      fn _changed, _arguments ->
        other
      end
    end
  end

  # Normalize slots when it's a map
  defp normalize_slots(slots) when is_map(slots) do
    Map.new(slots, &normalize_slot/1)
  end

  # Normalize slots when it's not a map
  defp normalize_slots(slots), do: slots |> Enum.into(%{}) |> normalize_slots()

  def as_slot(content) when is_function(content), do: content
  def as_slot(content), do: fn _assigns -> content end
end
