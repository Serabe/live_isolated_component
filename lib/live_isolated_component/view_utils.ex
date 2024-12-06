defmodule LiveIsolatedComponent.ViewUtils do
  @moduledoc """
  Collection of utils for people that want to write their own
  mock LiveView to use with `m:LiveIsolatedComponent.live_isolated_component/2`.
  """

  alias LiveIsolatedComponent.Hooks
  alias LiveIsolatedComponent.MessageNames
  alias LiveIsolatedComponent.StoreAgent
  alias LiveIsolatedComponent.Utils
  alias Phoenix.Component

  @doc """
  Run this in your mock view `c:Phoenix.LiveView.mount/3`.

  ## Options
  - `:on_mmount`, _boolean_, defaults to `true`. Can disable adding `on_mount` hooks.
  """
  def mount(params, session, socket, opts \\ []) do
    socket =
      socket
      |> Component.assign(:store_agent, session[MessageNames.store_agent_key()])
      |> run_on_mount(params, session, opts)
      |> Utils.update_socket_from_store_agent()

    {:ok, socket}
  end

  defp run_on_mount(socket, params, session, opts),
    do: run_on_mount(socket.assigns.store_agent, params, session, socket, opts)

  defp run_on_mount(agent, params, session, socket, opts) do
    on_mount = if Keyword.get(opts, :on_mount, true), do: StoreAgent.get_on_mount(agent), else: []

    on_mount
    |> add_lic_hooks()
    |> Enum.reduce(socket, &do_run_on_mount(&1, params, session, &2))
  end

  defp do_run_on_mount({module, first}, params, session, socket) do
    {:cont, socket} = module.on_mount(first, params, session, socket)
    socket
  end

  defp do_run_on_mount(module, params, session, socket),
    do: do_run_on_mount({module, :default}, params, session, socket)

  defp add_lic_hooks(list),
    do: [Hooks.HandleEventSpyHook, Hooks.HandleInfoSpyHook, Hooks.AssignsUpdateSpyHook | list]
end
