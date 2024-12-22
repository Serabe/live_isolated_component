defmodule LiveIsolatedComponent.View do
  @moduledoc false
  use Phoenix.LiveView

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveView

      @impl Phoenix.LiveView
      defdelegate mount(params, session, socket), to: LiveIsolatedComponent.ViewUtils

      @impl Phoenix.LiveView
      defdelegate render(assigns), to: LiveIsolatedComponent.ViewUtils

      @impl Phoenix.LiveView
      defdelegate handle_info(event, socket), to: LiveIsolatedComponent.ViewUtils

      @impl Phoenix.LiveView
      defdelegate handle_event(event, params, socket), to: LiveIsolatedComponent.ViewUtils

      defoverridable mount: 3, render: 1
    end
  end
end
