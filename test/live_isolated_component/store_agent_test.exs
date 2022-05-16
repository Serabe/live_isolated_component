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

    test "normalizes inner_block (fn)" do
      inner_block = fn assigns ->
        "Something with #{assigns}"
      end

      {:ok, pid} = StoreAgent.start(always(inner_block: inner_block))

      assert inner_block == pid |> StoreAgent.get_inner_block()
    end

    test "normalizes inner_block (not a fun)" do
      inner_block = "Some content"

      {:ok, pid} = StoreAgent.start(always(inner_block: inner_block))

      normalized_inner_block = StoreAgent.get_inner_block(pid)

      assert is_function(normalized_inner_block)
      assert inner_block == normalized_inner_block.(%{})
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

  describe "get_inner_block/1" do
    test "returns inner_block if present" do
      returned_value = %{something: :darkside}
      inner_block = fn _assigns -> returned_value end
      {:ok, pid} = StoreAgent.start(always(inner_block: inner_block))

      assert inner_block == StoreAgent.get_inner_block(pid)
    end

    test "returns a function returning the given inner_block if not a function" do
      inner_block = "Hello"
      {:ok, pid} = StoreAgent.start(always(inner_block: inner_block))

      returned_inner_block = StoreAgent.get_inner_block(pid)

      assert is_function(returned_inner_block, 1)
      assert inner_block == returned_inner_block.(%{})
    end

    test "returns a function if there is no inner_block" do
      {:ok, pid} = StoreAgent.start(always([]))

      returned_inner_block = StoreAgent.get_inner_block(pid)

      assert is_function(returned_inner_block, 1)
    end
  end

  defp always(value), do: fn -> value end
end
