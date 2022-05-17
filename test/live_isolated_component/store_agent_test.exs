defmodule LiveIsolatedComponent.StoreAgentTest do
  use ExUnit.Case

  alias LiveIsolatedComponent.StoreAgent

  describe "start/1" do
    test "normalizes assigns (map)" do
      assigns = %{a: "hola"}
      {:ok, pid} = StoreAgent.start(always(assigns: assigns))

      assert pid |> StoreAgent.get_assigns() |> Map.equal?(assigns)
    end

    test "normalizes assigns (enumerable)" do
      {:ok, pid} = StoreAgent.start(always(assigns: [a: "hola", b: "adios"]))

      assert pid |> StoreAgent.get_assigns() |> Map.equal?(%{a: "hola", b: "adios"})
    end
  end

  describe "get_assigns/1" do
    test "returns passed assigns" do
      assigns = %{a: "hola"}
      {:ok, pid} = StoreAgent.start(always(assigns: assigns))

      assert pid |> StoreAgent.get_assigns() |> Map.equal?(assigns)
    end

    test "returns empty map if assigns is not passed" do
      {:ok, pid} = StoreAgent.start(always(%{}))

      assert pid |> StoreAgent.get_assigns() |> Map.equal?(%{})
    end
  end

  describe "get_handle_event/1" do
    test "returns handle event if passed" do
      handle_event = fn _e, _p, _s -> {:something, :darkside} end
      {:ok, pid} = StoreAgent.start(always(handle_event: handle_event))

      returned_handle_event = StoreAgent.get_handle_event(pid)

      assert is_function(returned_handle_event)

      assert {:something, :darkside} = returned_handle_event.([], [], [])
    end

    test "returns a default handler if not present" do
      {:ok, pid} = StoreAgent.start(always([]))

      returned_handle_event = StoreAgent.get_handle_event(pid)

      assert is_function(returned_handle_event)

      socket = %{a: :something}

      assert {:noreply, ^socket} = returned_handle_event.([], [], socket)
    end
  end

  describe "get_handle_info/1" do
    test "returns handle event if passed" do
      handle_info = fn _e, _s -> {:something, :darkside} end
      {:ok, pid} = StoreAgent.start(always(handle_info: handle_info))

      returned_handle_info = StoreAgent.get_handle_info(pid)

      assert is_function(returned_handle_info)

      assert {:something, :darkside} = returned_handle_info.([], [])
    end

    test "returns a default handler if not present" do
      {:ok, pid} = StoreAgent.start(always([]))

      returned_handle_info = StoreAgent.get_handle_info(pid)

      assert is_function(returned_handle_info)

      socket = %{a: :something}

      assert {:noreply, ^socket} = returned_handle_info.([], socket)
    end
  end

  defp always(value), do: fn -> value end
end
