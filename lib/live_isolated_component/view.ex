defmodule LiveIsolatedComponent.View do
  @moduledoc """
  This module serves as a starting point to creating your own
  mock views for `LiveIsolatedComponent`.

  You might want to use custom mock views for multiple reasons
  (using some custom UI library like `Surface`, having important
  logic in hooks...). In any case, think whether or not the test
  can work and test effectively the isolated behaviour of your
  component. If that is not the case, you are welcomed to use
  your own mock view.

  ## Custom `c:Phoenix.LiveView.mount/3`

  Just override the callback and make sure to call `LiveIsolatedComponent.ViewUtils.mount/3`
  to properly initialize the socket to work with `LiveIsolatedComponent`. Refer to the
  documentation of the util and to the callback for more specific usages.

  ## Custom `c:Phoenix.LiveView.render/1`

  The given assigns contain the following keys you can use to create your custom render:

  - `@component` contains the passed in component, be it a function or a module.
  - `@assigns` contains the list of given assigns for the component.
  - `@slots` for the given slots. If you are having problems rendering slots, use `LiveIsolatedComponent.ViewUtils.prerender_slots/1`
    with the full assigns to get a pre-rendered list of slots.

  ## Custom `c:Phoenix.LiveView.handle_info/2` and `c:Phoenix.LiveView.handle_event/3`

  Either use an `m:Phoenix.LiveView.on_mount/1` hook or one of the options in
  `m:LiveIsolatedComponent.live_isolated_component/2`. There is some convoluted
  logic in these handles and already some work put on making them extensible with these
  mechanisms to make overriding them worthy.
  """
  use Phoenix.LiveView

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveView

      @impl Phoenix.LiveView
      def mount(params, session, socket),
        do: {:ok, LiveIsolatedComponent.ViewUtils.mount(params, session, socket)}

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
