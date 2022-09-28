defmodule LiveIsolatedComponent.StoreAgent do
  @moduledoc false

  def start(fun) do
    Agent.start(fn ->
      fun.() |> normalize_options()
    end)
  end

  def stop(agent, reason \\ :normal, timeout \\ :infinity) do
    Agent.stop(agent, reason, timeout)
  end

  def get_assigns(pid), do: pid |> get_data(:assigns, %{}) |> Map.put_new(:id, "some-unique-id")

  def get_component(pid), do: get_data(pid, :component, nil)

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

  def send_to_test(pid, message) do
    send(get_data(pid, :test_pid), message)
  end

  defp get_data(pid, key, default_value \\ nil) do
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

  # Normalize slots when it's not a map
  # If slot is just the default slot
  defp normalize_slots(%{__live_isolated_slot__: true} = slot),
    do: normalize_slots(%{inner_block: [slot]})

  # If slots is a map we just make sure the values are lists
  defp normalize_slots(slots) when is_map(slots) do
    Map.new(slots, fn
      {key, value} when is_list(value) -> {key, value}
      {key, value} -> {key, [value]}
    end)
  end

  # If slots are other, we make sure the convert to map nicely
  defp normalize_slots(slots) do
    if Keyword.keyword?(slots) do
      # If it is a keyword, we group all the values nicely
      slots
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
      |> Map.new(fn {key, value} -> {key, List.flatten(value)} end)
    else
      slots |> Enum.into(%{}) |> normalize_slots()
    end
  end

  def as_slot(content) when is_function(content), do: content
  def as_slot(content), do: fn _assigns -> content end
end
