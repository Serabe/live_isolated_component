defmodule LiveIsolatedComponent.HandleInfoSpy do
  def new(default_impl \\ fn _e, s -> {:noreply, s} end) do
    {:ok, spy} = Agent.start_link(fn -> [] end)

    callback = fn event, socket ->
      arguments = {event, socket}
      result = default_impl.(event, socket)
      Agent.update(spy, fn list -> [%{arguments: arguments, result: result} | list] end)

      result
    end

    {spy, callback}
  end

  def received_anything?(agent) do
    Agent.get(agent, fn list -> !Enum.empty?(list) end)
  end

  def last_event(agent) do
    :sys.get_state(agent)
    Agent.get(agent, &hd/1)
  end

  def events(agent) do
    agent
    |> Agent.get(& &1)
    |> Enum.reverse()
  end
end
