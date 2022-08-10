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

The `slots` options can be:

1. Just a slot. In that case, it'd be taken as the default slot.
2. A map or keywords. In this case, the keys are the name of the slots, the values
   can either be a slot or an array of slots. In case of keywords, the values
   will be collected for the same slot name.

### Defining a slot

We define slots by using the `slot` macro. This macro accepts a keyword list and a block.
The block needs to return a template (you can use `sigil_H`). The keywords will be considered
attributes of the slot except for the following `let`:

- `let` will bind the argument to the value. You can use destructuring here.

Like in a real slot, the `assigns` the slot have access to is that of the parent LiveView.

### Slot Examples

Just a default slot:

```elixir
{:ok, view, html} = live_isolated_component(MyComponent,
  slots: slot(assigns: assigns) do
    ~H[Hello from default slot]
  end
)
```

Just a default slot (map version):

```elixir
{:ok, view, html} = live_isolated_component(MyComponent,
  slots: %{
    inner_block: slot(assigns: assigns) do
      ~H[Hello from default slot]
    end
  }
)
```

Named slot (only one slot defined):

```elixir
{:ok, view, html} = live_isolated_component(MyTableComponent,
  slots: %{
    col: slot(assigns: assigns, header: "Column Header") do
      ~H[Hello from the column slot]
    end
  }
)
```

Named slot (multiple slots defined):

```elixir
{:ok, view, html} = live_isolated_component(MyTableComponent,
  slots: %{
    col: [
      slot(assigns: assigns, let: item, header: "Language") do
        ~H[<%= item.language %>]
      end,
      slot(assigns: assigns, let: %{greeting: greeting}, header: "Greeting") do
        ~H[<%= greeting %>]
      end
    ]
  }
)
```
