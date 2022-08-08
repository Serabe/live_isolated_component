# LiveIsolatedComponent

The simplest way to test a LiveView both stateful and function component in isolation
while keeping the interactivity.

## Installation

```elixir
def deps do
  [
    {:live_isolated_component, "~> 0.1.1", only: [:dev, :test]}
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
{:ok, view, _html} = live_isolated_component(SimpleButton,
    assigns: %{on_click: :i_was_clicked}
  )

view
  |> element("button")
  |> render_click()

assert_handle_event view, :i_was_clicked
```

Testing `handle_info`:

```elixir
{:ok, view, _html} = live_isolated_component(ComplexButton,
    assigns: %{on_click: :i_was_clicked}
  )

view
  |> element("button")
  |> render_click()

assert_handle_info view, :i_was_clicked
```

`handle_event` callback:

```elixir
{:ok, view, _html} = live_isolated_component(SimpleButton,
    assigns: %{on_click: :i_was_clicked},
    handle_event: fn :i_was_clicked, _params, socket ->
      # Do something
      {:noreply, socket}
    end
  )
```

`handle_info` callback:

```elixir
{:ok, view, _html} = live_isolated_component(SimpleButton,
    assigns: %{on_click: :i_was_clicked},
    handle_info: fn :i_was_clicked, _params, socket ->
      # Do something
      {:noreply, socket}
    end
  )
```

## Slots

The `slots` options can be either a map or keywords. Each key represents one slot. There are several ways to represent a slot:

1. A slot can be just a hex template.
2. A slot can be a function of arity 2. If so, it will receive as first parameter the changed properties and as the second the assigns. This function depends on LV implementation of slots, so it's subject to change if LV changes it. It needs to return either a template or a list of templates.
3. A function of arity 1. In this case, it'll receive the assigns passed to the `live_isolated_component` macro. It can either return a template, a list of templates or a function as described in 2. This is an abstraction over the underlying implementation and, if possible, will not change even if LV changes the implementation.
4. A list of Slots as describes in 1., 2. and 3. combined in any way.

```elixir
{:ok, view, _html} = live_isolated_component(TableComponent,
  assigns: %{key: "value"},
  slots: %{
    col: [
      ~H"""
      One
      """,
      %{
      inner_block: ~H"""
      Two
      """
      },
      fn assigns ->
        ~H"""
        <%= @key %>
        """
      end,
      fn _changed, assigns ->
        ~H"""
        <%= @es %> <%= @en %>
        """
      end,
      fn view_assigns ->
        fn _changed, arguments ->
          assigns = Map.merge(view_assigns, arguments)
          ~H"""
          <%= @es %> <%= @key %> <%= @en %>
          """
        end
      end
    ]
  }
)
```
