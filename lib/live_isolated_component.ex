defmodule LiveIsolatedComponent do
  @moduledoc """
  Functions for testing LiveView stateful components in isolation easily.
  """

  import Phoenix.ConnTest, only: [build_conn: 0]
  import Phoenix.LiveViewTest, only: [live_isolated: 3, render: 1]

  alias LiveIsolatedComponent.StoreAgent

  defmodule Utils do
    import Phoenix.Component

    def store_agent_pid(%{assigns: %{store_agent: pid}}) when is_pid(pid),
      do: pid

    def update_socket_from_store_agent(socket) do
      agent = Utils.store_agent_pid(socket)

      component = StoreAgent.get_component(agent)

      socket
      |> assign(:assigns, StoreAgent.get_assigns(agent))
      |> assign(:component, component)
      |> assign(:slots, StoreAgent.get_slots(agent))
    end

    def denormalize_socket(socket, original_assigns) do
      socket
      |> Map.put(:assigns, original_assigns)
      |> assign(:assigns, socket.assigns)
    end

    def normalize_socket(socket, original_assigns) do
      assign_like_structure = Map.put(original_assigns.assigns, :__changed__, %{})
      Map.put(socket, :assigns, assign_like_structure)
    end

    def send_to_test(socket, original_assigns, message) do
      socket
      |> denormalize_socket(original_assigns)
      |> Utils.store_agent_pid()
      |> StoreAgent.send_to_test(message)
    end

  end

  defmodule HandleEventSpyHook do
    import Phoenix.LiveView

    def on_mount(:default, _params, _session, socket) do
      {:cont, attach_hook(socket, :lic_handle_event_spy, :handle_event, &handle_event/3)}
    end

    def handle_event(event, params, socket) do
      original_assigns = socket.assigns

      Utils.send_to_test(
        socket,
        original_assigns,
        {LiveIsolatedComponent.MessageNames.handle_event_received_message(), self(), {event, params}}
      )

      {:cont, socket}
    end
  end

  defmodule HandleInfoSpyHook do
    import Phoenix.LiveView

    def on_mount(:default, _params, _session, socket) do
      {:cont, attach_hook(socket, :lic_handle_info_spy, :handle_info, &handle_info/2)}
    end

    def handle_info(event, socket) do
      original_assigns = socket.assigns

      Utils.send_to_test(
        socket,
        original_assigns,
        {LiveIsolatedComponent.MessageNames.handle_info_received_message(), self(), event}
      )

      {:cont, socket}
    end

  end

  defmodule AssignsUpdateSpyHook do
    import Phoenix.LiveView

    @event_name LiveIsolatedComponent.MessageNames.updates_event()

    def on_mount(:default, _params, _session, socket) do
      {:cont, attach_hook(socket, :lic_assings_update, :handle_info, &handle_info/2)}
    end

    def handle_info({@event_name, pid}, socket) do
      values = Agent.get(pid, & &1)
      Agent.stop(pid)

      socket
      |> Utils.store_agent_pid()
      |> StoreAgent.update(values)

      {:halt, Utils.update_socket_from_store_agent(socket)}
    end

    def handle_info(_message, socket), do: {:cont, socket}
  end

  defmodule View do
    @moduledoc false

    use Phoenix.LiveView

    alias Phoenix.LiveView.TagEngine

    def mount(params, session, socket) do
      socket =
        socket
        |> assign(:store_agent, session[LiveIsolatedComponent.MessageNames.store_agent_key()])
        |> run_on_mount(params, session)
        |> Utils.update_socket_from_store_agent()

      {:ok, socket}
    end

    def render(%{component: component, store_agent: agent, assigns: component_assigns} = _assigns)
        when is_function(component) do
      TagEngine.component(
        component,
        Map.merge(
          component_assigns,
          StoreAgent.get_slots(agent, component_assigns)
        ),
        {__ENV__.module, __ENV__.function, __ENV__.file, __ENV__.line}
      )
    end

    def render(assigns) do
      new_inner_assigns = Map.put_new(assigns.assigns, :id, "some-unique-id")

      assigns = Map.put(assigns, :assigns, new_inner_assigns)

      ~H"""
        <.live_component
          id={@assigns.id}
          module={@component}
          {@assigns}
          {@slots}
          />
      """
    end

    def handle_info(event, socket) do
      handle_info = socket |> Utils.store_agent_pid() |> StoreAgent.get_handle_info()
      original_assigns = socket.assigns

      {:noreply, socket} = handle_info.(event, Utils.normalize_socket(socket, original_assigns))

      {:noreply, Utils.denormalize_socket(socket, original_assigns)}
    end

    def handle_event(event, params, socket) do
      handle_event = socket |> Utils.store_agent_pid() |> StoreAgent.get_handle_event()
      original_assigns = socket.assigns

      result = handle_event.(event, params, Utils.normalize_socket(socket, original_assigns))

      Utils.send_to_test(
        socket,
        original_assigns,
        {LiveIsolatedComponent.MessageNames.handle_event_result_message(), self(), handle_event_result_as_event_param(result)}
      )

      denormalize_result(result, original_assigns)
    end

    defp handle_event_result_as_event_param({:noreply, _socket}), do: :noreply
    defp handle_event_result_as_event_param({:reply, map, _socket}), do: {:reply, map}

    defp denormalize_result({:noreply, socket}, original_assigns),
      do: {:noreply, Utils.denormalize_socket(socket, original_assigns)}

    defp denormalize_result({:reply, map, socket}, original_assigns),
      do: {:reply, map, Utils.denormalize_socket(socket, original_assigns)}


    defp run_on_mount(socket, params, session),
      do: run_on_mount(socket.assigns.store_agent, params, session, socket)

    defp run_on_mount(agent, params, session, socket) do
      agent |> StoreAgent.get_on_mount() |> add_lic_hooks() |> Enum.reduce(socket, &do_run_on_mount(&1, params, session, &2))
    end

    defp do_run_on_mount({module, first}, params, session, socket) do
      {:cont, socket} = module.on_mount(first, params, session, socket)
      socket
    end

    defp do_run_on_mount(module, params, session, socket),
      do: do_run_on_mount({module, :default}, params, session, socket)

    defp add_lic_hooks(list),
      do: [HandleEventSpyHook, HandleInfoSpyHook, AssignsUpdateSpyHook | list]
  end

  @doc """
  Updates the assigns of the component.

      {:ok, view, _html} = live_isolated_component(SomeComponent, assigns: %{description: "blue"})

      live_assign(view, %{description: "red"})
  """
  def live_assign(view, keyword_or_map) do
    # We need to use agents because fns are not serializable.
    # The LV will stop this agent
    {:ok, pid} = Agent.start(fn -> %{assigns: Enum.into(keyword_or_map, %{})} end)

    send(view.pid, {LiveIsolatedComponent.MessageNames.updates_event(), pid})

    render(view)

    view
  end

  @doc """
  Updates the key in assigns of the component.

      {:ok, view, _html} = live_isolated_component(SomeComponent, assigns: %{description: "blue"})

      live_assign(view, :description, "red")
  """
  def live_assign(view, key, value) do
    live_assign(view, %{key => value})
  end

  @doc """
  Renders the given component in isolation and live so you can tested like you would
  test any LiveView.

  It accepts the following options:
    - `:assigns` accepts a map of assigns for the component.
    - `:handle_event` accepts a handler for the `handle_event` callback in the LiveView.
    - `:handle_info` accepts a handler for the `handle_info` callback in the LiveView.
    - `:on_mount` accepts a list of either modules or tuples `{Module, parameter}`. See `Phoenix.LiveView.on_mount/1` for more info on the parameters.
    - `:slots` accepts different slot descriptors.

  ## More about slots

  For defining slots, you need to use the `slot/2` macro. If you just pass a slot
  to `:slots`, it will be taken as a default sot (`@inner_block` inside the component).

  You can also pass a map or keywords to `:slots`. In this case, the key is considered
  to be the slot name and the value, the different slots. Remember that the default slot's
  name is `inner_block`.

  For passing multiple slots for the same name, you have two options:any()

  1. You can give an array of slots as the value in the map or the keywords.
  2. You can pass the same name multiple times with different slots. This option
     is only available if you are using keywords, as this data structure preserves
     all values.
  """
  defmacro live_isolated_component(component, opts \\ quote(do: %{})) do
    quote do
      opts = if is_map(unquote(opts)), do: [assigns: unquote(opts)], else: unquote(opts)
      test_pid = self()

      # We need to use agents because fns are not serializable.
      {:ok, store_agent} =
        StoreAgent.start(fn ->
          %{
            assigns: Keyword.get(opts, :assigns, %{}),
            component: unquote(component),
            handle_event: Keyword.get(opts, :handle_event),
            handle_info: Keyword.get(opts, :handle_info),
            on_mount: Keyword.get(opts, :on_mount),
            slots: Keyword.get(opts, :slots),
            test_pid: test_pid
          }
        end)

      live_isolated(build_conn(), View,
        session: %{
          unquote(LiveIsolatedComponent.MessageNames.store_agent_key()) => store_agent
        }
      )
    end
  end

  @doc """
  Asserts the return value of a handle_event
  """
  defmacro assert_handle_event_return(view, return_value) do
    quote do
      view_pid = unquote(view).pid

      :sys.get_state(view_pid)

      assert_receive {unquote(LiveIsolatedComponent.MessageNames.handle_event_result_message()), ^view_pid, unquote(return_value)}
    end
  end

  @doc """
  Asserts that a given handle event has been received.

  Depending on the number of parameters, different parts are checked:

  - With no parameters, just that a handle_event message has been received.
  - With one parameter, just the event name is checked.
  - With two parameters, both event name and the parameters are checked.
  - The optional last argument is the timeout, defaults to 500 milliseconds

  If you just want to check the parameters without checking the event name,
  pass `nil` as the event name.
  """
  defmacro assert_handle_event(view, event \\ nil, params \\ nil, timeout \\ 500) do
    event = if is_nil(event), do: quote(do: _event), else: event
    params = if is_nil(params), do: quote(do: _params), else: params

    quote do
      view_pid = unquote(view).pid

      :sys.get_state(view_pid)

      assert_receive {unquote(LiveIsolatedComponent.MessageNames.handle_event_received_message()), ^view_pid,
                      {unquote(event), unquote(params)}},
                     unquote(timeout)
    end
  end

  @doc """
  Refutes that a given handle event has been received.

  Depending on the number of parameters, different parts are checked:

  - With no parameters, just that a handle_event message has not been received.
  - With one parameter, just the event name is checked.
  - With two parameters, both event name and the parameters are checked.
  - The optional last argument is the timeout, defaults to 500 milliseconds

  If you just want to check the parameters without checking the event name,
  pass `nil` as the event name.
  """
  defmacro refute_handle_event(view, event \\ nil, params \\ nil, timeout \\ 500) do
    event = if is_nil(event), do: quote(do: _event), else: event
    params = if is_nil(params), do: quote(do: _params), else: params

    quote do
      view_pid = unquote(view).pid

      :sys.get_state(view_pid)

      refute_receive {unquote(LiveIsolatedComponent.MessageNames.handle_event_received_message()), ^view_pid,
                      {unquote(event), unquote(params)}, _},
                     unquote(timeout)
    end
  end

  @doc """
  Asserts that a given handle_info event has been received.

  If only the view is passed, only that a handle_info is received is checked.
  With an optional event name, we check that too.
  The third argument is an optional timeout, defaults to 500 milliseconds.
  """
  defmacro assert_handle_info(view, event \\ nil, timeout \\ 500) do
    event = if is_nil(event), do: quote(do: _event), else: event

    quote do
      view_pid = unquote(view).pid

      :sys.get_state(view_pid)

      assert_receive {unquote(LiveIsolatedComponent.MessageNames.handle_info_received_message()), ^view_pid, unquote(event)},
                     unquote(timeout)
    end
  end

  @doc """
  Asserts that a given handle_info event has not been received.

  If only the view is passed, only that a handle_info is not received is checked.
  With an optional event name, we check that too.
  The third argument is an optional timeout, defaults to 500 milliseconds.
  """
  defmacro refute_handle_info(view, event \\ nil, timeout \\ 500) do
    event = if is_nil(event), do: quote(do: _event), else: event

    quote do
      view_pid = unquote(view).pid

      :sys.get_state(view_pid)

      refute_receive {unquote(LiveIsolatedComponent.MessageNames.handle_info_received_message()), ^view_pid, unquote(event)},
                     unquote(timeout)
    end
  end

  @doc """
  Macro to define slots. Accepts a map or keywords and a block.
  The block needs to return a template (use a `sigil_H`).

  The arguments can be anything and they will be passed to the slot
  as attributes. There is only one special attribute that will not
  be passed though:

  1. `let` behaves like in components, letting the component
     pass some value into the slot.

  ## Example

  ```
  > slot(let: {key, value}) do
      ~H[
      <div>
        <h2>Title coming from assigns: <%= @title %></h2>
        <span>Key coming from let <%= key %></span>
        <span>Value coming from let<%= value %></span>
      </div>
      ]
    end
  ```

  ## Conversion

  In case you are wondering how to convert a slot in HEEX
  to the slot macro, let's do a simple conversion from a
  named slot with attributes:any()

  ```heex
  <:slot_name attr_1={5} attr_2="hola" let={value}>
    <span>Received value from parent component is <%= value %></span>
  </:slot_name>
  ```

  For converting this, we notice three different parts:

  1. The slot name. In this case, `:slot_name`.
  2. The slot attributes. In this case, `attr_1={5} attr_2="hola" let={value}`.
  3. The slot content (or inner_block). In this case, the `span`.

  Thus, we just need to pass to the `slots` options the following value (just
  showing the keyword options to `live_isolated_component`):

  ```elixir
  [
    slots: [
      slot_name: slot(attr_1: 5, attr_2: "hola", let: value) do
        ~H[<span>Received value from parent component is <%= value %></span>]
      end
    ]
  ]
  ```
  """
  defmacro slot(args \\ quote(do: %{}), do: block) do
    {:%{}, metadata, content} =
      case args do
        {:%{}, _metadata, _content} = map -> map
        keywords -> {:%{}, [], keywords}
      end

    {_assigns, without_assigns} = Keyword.pop(content, :assigns, quote(do: assigns))

    {let_name, without_assigns_and_let} =
      Keyword.pop(without_assigns, :let, quote(do: __inner_let))

    # Add the with block to deal with warning because of the let.
    # In LV 0.18 a warning was introduced to prevent the use of
    # variables outside the assigns:
    # https://github.com/phoenixframework/phoenix_live_view/blob/82b349278cc5ced4f0c99fe27d0988b42197d8ce/lib/phoenix_live_view/engine.ex#L1085-L1107
    # This fixes this warning as it sets the value using a with block.
    block =
      Macro.prewalk(block, fn
        {:sigil_H, meta, content} ->
          {:<<>>, str_meta, [str]} = content |> hd()

          new_str =
            "<%= with #{Macro.to_string(let_name)} <- @__lic_component_slot_let__ do %>#{str}<% end %>"

          {:sigil_H, meta, [{:<<>>, str_meta, [new_str]} | tl(content)]}

        other ->
          other
      end)

    slot_attrs = {:%{}, metadata, without_assigns_and_let}

    quote do
      unquote(slot_attrs)
      |> Map.new()
      |> Map.merge(%{
        __live_isolated_slot__: true,
        inner_block: fn var!(assigns) ->
          fn _changed, let_value ->
            var!(assigns) = Map.put(var!(assigns), :__lic_component_slot_let__, let_value)

            unquote(block)
          end
        end
      })
    end
  end
end
