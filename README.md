# LiveIsolatedComponent

The simplest way to test a LiveView stateful component in isolation.

## Installation

```elixir
def deps do
  [
    {:live_isolated_component, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/live_isolated_component>.

## Basic usage

Importing `LiveIsolatedComponent` will import one function, `live_assign`, and one macro, `live_isolated_component`. You can use `live_isolated_component` like you would use `live_isolated`, just pass the component you want to test as the first argument and use the options as you see fit. If you want to change the passed assigns from the test, use `live_assign` with the view instead of the socket.

## Example

Simple rendering:

```elixir
{:ok, view, _html} = live_isolated_component(SimpleButton)

assert has_element?(view, ".count", "Clicked 0 times")

view
  |> element("button")
  |> render_click()

assert has_element?(view, ".count", "Clicked 1 times")
```

Testing assigns:

```elixir
{:ok, view, _html} = live_isolated_component(Greeting, %{name: "Sergio"})

assert has_element?(view, ".name", "Sergio")

live_assign(view, :name, "Fran")
# or
# live_assign(view, name: "Fran")
# or
# live_assign(view, %{name: "Fran"})

assert has_element?(view, ".name", "Fran")
```

Testing `handle_event`:

```elixir
# alias LiveIsolatedComponent.Spy
handle_event_spy = Spy.handle_event()

{:ok, view, _html} = live_isolated_component(SimpleButton,
    assigns: %{on_click: :i_was_clicked},
    handle_event: handle_event_spy.callback
  )

view
  |> element("button")
  |> render_click()

assert %{arguments: {:i_was_clicked, _p, _s}} = Spy.last_event(handle_event_spy)
```

Testing `handle_info`:

```elixir
# alias LiveIsolatedComponent.Spy
handle_info_spy = Spy.handle_info()

{:ok, view, _html} = live_isolated_component(ComplexButton,
    assigns: %{on_click: :i_was_clicked},
    handle_info: handle_info_spy.callback
  )

view
  |> element("button")
  |> render_click()

assert %{arguments: {:i_was_clicked, _s}} = Spy.last_event(handle_event_spy)
```

Passing a default slot:

```elixir
assigns = %{}
{:ok, view, _html} = live_isolated_component(LabelComponent,
    content: ~H"""
    <div>Some content</div>
    """
  )
```

```elixir
{:ok, view, _html} = live_isolated_component(LabelComponent,
    assigns: %{name: "Sergio"},
    content: fn assigns ->
      # We get the assigns passed to `live_isolated_component`
      ~H"""
      <div><%= @name %></div>
      """
    end
  )
```
