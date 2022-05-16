defmodule LiveIsolatedComponent.SpyTest do
  use ExUnit.Case

  alias LiveIsolatedComponent.Spy

  describe "handle_event/1" do
    test "default impl just returns {:noreply, socket}" do
      spy = Spy.handle_event()

      socket = %{something: "Dark side"}

      assert {:noreply, ^socket} = spy.callback.(:event, %{}, socket)
    end

    test "calls implementation if given one" do
      returned_socket = %{something: "else"}
      spy = Spy.handle_event(fn _e, _p, _s -> {:noreply, returned_socket} end)

      socket = %{something: "Dark side"}

      assert {:noreply, ^returned_socket} = spy.callback.(:event, %{}, socket)
    end

    test "registers arguments" do
      spy = Spy.handle_event()

      event_name = {:some, "complex_event"}
      params = %{a: "param"}
      socket = %{something: "Dark side"}

      assert {:noreply, ^socket} = spy.callback.(event_name, params, socket)

      assert %{arguments: {^event_name, ^params, ^socket}} = Spy.last_event(spy)
    end

    test "registers result" do
      returned_socket = %{something: "else"}
      spy = Spy.handle_event(fn _e, _p, _s -> {:noreply, returned_socket} end)

      socket = %{something: "Dark side"}

      assert {:noreply, ^returned_socket} = spy.callback.(:event, %{}, socket)

      assert %{result: {:noreply, ^returned_socket}} = Spy.last_event(spy)
    end

    test "registers multiple calls in order" do
      spy = Spy.handle_event()

      spy.callback.("event_1", %{a: 1}, %{socket: 1})
      spy.callback.("event_2", %{a: 2}, %{socket: 2})
      spy.callback.("event_3", %{a: 3}, %{socket: 3})

      assert [
               %{arguments: {"event_1", %{a: 1}, %{socket: 1}}},
               %{arguments: {"event_2", %{a: 2}, %{socket: 2}}},
               %{arguments: {"event_3", %{a: 3}, %{socket: 3}}}
             ] = Spy.events(spy)
    end
  end

  describe "handle_info/1" do
    test "default impl just returns {:noreply, socket}" do
      spy = Spy.handle_info()

      socket = %{something: "Dark side"}

      assert {:noreply, ^socket} = spy.callback.(:event, socket)
    end

    test "calls implementation if given one" do
      returned_socket = %{something: "else"}
      spy = Spy.handle_info(fn _e, _s -> {:noreply, returned_socket} end)

      socket = %{something: "Dark side"}

      assert {:noreply, ^returned_socket} = spy.callback.(:event, socket)
    end

    test "registers arguments" do
      spy = Spy.handle_info()

      event_name = {:some, "complex_event"}
      socket = %{something: "Dark side"}

      assert {:noreply, ^socket} = spy.callback.(event_name, socket)

      assert %{arguments: {^event_name, ^socket}} = Spy.last_event(spy)
    end

    test "registers result" do
      returned_socket = %{something: "else"}
      spy = Spy.handle_info(fn _e, _s -> {:noreply, returned_socket} end)

      socket = %{something: "Dark side"}

      assert {:noreply, ^returned_socket} = spy.callback.(:event, socket)

      assert %{result: {:noreply, ^returned_socket}} = Spy.last_event(spy)
    end

    test "registers multiple calls in order" do
      spy = Spy.handle_info()

      spy.callback.("event_1", %{socket: 1})
      spy.callback.("event_2", %{socket: 2})
      spy.callback.("event_3", %{socket: 3})

      assert [
               %{arguments: {"event_1", %{socket: 1}}},
               %{arguments: {"event_2", %{socket: 2}}},
               %{arguments: {"event_3", %{socket: 3}}}
             ] = Spy.events(spy)
    end
  end

  describe "events/1" do
    test "returns all the handled events in order" do
      spy = Spy.handle_info()

      spy.callback.("event_1", %{socket: 1})
      spy.callback.("event_2", %{socket: 2})
      spy.callback.("event_3", %{socket: 3})

      assert [
               %{arguments: {"event_1", %{socket: 1}}},
               %{arguments: {"event_2", %{socket: 2}}},
               %{arguments: {"event_3", %{socket: 3}}}
             ] = Spy.events(spy)
    end
  end

  describe "las_event/1" do
    test "returns nil if no event" do
      spy = Spy.handle_event()

      assert nil == Spy.last_event(spy)
    end

    test "returns last event" do
      spy = Spy.handle_event()

      spy.callback.("event_1", %{a: 1}, %{socket: 1})
      spy.callback.("event_2", %{a: 2}, %{socket: 2})
      spy.callback.("event_3", %{a: 3}, %{socket: 3})

      assert %{arguments: {"event_3", %{a: 3}, %{socket: 3}}} = Spy.last_event(spy)
    end
  end

  describe "any_event_received?/1" do
    test "returns false if no event received" do
      spy = Spy.handle_event()

      refute Spy.any_event_received?(spy)
    end

    test "returns true if one message was received" do
      spy = Spy.handle_event()

      spy.callback.("event_1", %{a: 1}, %{socket: 1})

      assert Spy.any_event_received?(spy)
    end

    test "returns true if multiple messages were received" do
      spy = Spy.handle_event()

      spy.callback.("event_1", %{a: 1}, %{socket: 1})
      spy.callback.("event_2", %{a: 2}, %{socket: 2})
      spy.callback.("event_3", %{a: 3}, %{socket: 3})

      assert Spy.any_event_received?(spy)
    end
  end
end
