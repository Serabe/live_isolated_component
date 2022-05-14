defmodule LiveIsolatedComponent.Spy do
  @doc """
  Creates an spy for a handle_event.

      handle_event_spy = Spy.handle_event()

      {:ok, view, _html} = live_isolated_component(SomeComponent, handle_event: handle_event_spy.callback)

      view
        |> element("button")
        |> render_click()

      assert Spy.any_event_received?(handle_event_spy)
  """
  def handle_event(default_impl \\ fn _e, _p, s -> {:noreply, s} end) do
    {:ok, spy} = Agent.start_link(fn -> [] end)

    callback = fn event, params, socket ->
      arguments = {event, params, socket}
      result = default_impl.(event, params, socket)

      Agent.update(spy, fn list ->
        [%{arguments: arguments, result: result} | list]
      end)

      result
    end

    %{spy: spy, callback: callback}
  end

  @doc """
  Creates an spy for a handle_info.

      handle_info_spy = Spy.handle_info()

      {:ok, view, _html} = live_isolated_component(SomeComponent, handle_info: handle_info_spy.callback)

      view
        |> element("button")
        |> render_click()

      assert Spy.any_event_received?(handle_info_spy)
  """
  def handle_info(default_impl \\ fn _e, s -> {:noreply, s} end) do
    {:ok, spy} = Agent.start_link(fn -> [] end)

    callback = fn event, socket ->
      arguments = {event, socket}
      result = default_impl.(event, socket)

      Agent.update(spy, fn list ->
        [%{arguments: arguments, result: result} | list]
      end)

      result
    end

    %{spy: spy, callback: callback}
  end

  @doc """
  Returns all the events in the spy.
  """
  def events(%{spy: spy}) do
    :sys.get_state(spy)

    spy
    |> Agent.get(& &1)
    |> Enum.reverse()
  end

  @doc """
  Returns the last event registered in the spy.
  """
  def last_event(%{spy: spy}) do
    :sys.get_state(spy)

    Agent.get(spy, &hd/1)
  end

  @doc """
  Checks if any event was registered at all.
  """
  def any_event_received?(%{spy: spy}) do
    :sys.get_state(spy)

    Agent.get(spy, fn list ->
      !Enum.empty?(list)
    end)
  end
end
