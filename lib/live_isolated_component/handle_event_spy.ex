defmodule LiveIsolatedComponent.HandleEventSpy do
  def new do
    {:ok, spy} = Agent.start_link(fn -> [] end)

    callback = fn event, params, socket ->
      Agent.update(spy, fn list -> [{event, params, socket} | list] end)
      {:noreply, socket}
    end

    {spy, callback}
  end

  def received_anything?(agent) do
    Agent.get(agent, fn list -> !Enum.empty?(list) end)
  end

  def last_event(agent) do
    Agent.get(agent, &hd/1)
  end

  def events(agent) do
    agent
    |> Agent.get(& &1)
    |> Enum.reverse()
  end
end
