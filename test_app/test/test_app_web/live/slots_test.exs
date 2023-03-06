defmodule TestAppWeb.Live.TableComponentTest do
  use TestAppWeb.ConnCase, async: true

  alias TestAppWeb.Live.TimesTwoComponent

  import LiveIsolatedComponent
  import Phoenix.LiveViewTest
  import Phoenix.Component, only: [render_slot: 1, render_slot: 2, sigil_H: 2]

  for {label, type_of_slot} <- [{"as default slot", :default}, {"as named slot", :named}] do
    @label label
    @type_of_slot type_of_slot

    describe "default (inner_block) slot #{@label}" do
      test "displays slot" do
        inner_block =
          slot do
            ~H[Hola]
          end

        {:ok, view, _html} =
          live_isolated_component(
            fn assigns ->
              ~H[<div data-test-hola><%= render_slot @inner_block %></div>]
            end,
            slots: process_slot(inner_block, @type_of_slot)
          )

        assert has_element?(view, "[data-test-hola]", "Hola")
      end

      @tag :let_warning
      test "accepts arguments (simple)" do
        {:ok, view, _html} =
          live_isolated_component(TimesTwoComponent,
            assigns: %{
              value: 2
            },
            slots:
              process_slot(
                slot(%{let: arg}) do
                  if 2 * 3 == 5 do
                    ~H[Yes <%= arg %>]
                  else
                    ~H[Not <%= arg %>]
                  end
                end,
                @type_of_slot
              )
          )

        assert has_element?(view, "[data-phx-component]", "No 4")
      end

      test "accepts arguments (destructuring)" do
        {:ok, view, _html} =
          live_isolated_component(&pass_value_to_default_slot/1,
            assigns: %{value: {"hola", "adios"}},
            slots:
              process_slot(
                slot(let: {a, b}) do
                  ~H"""
                  <span data-test-hola><%= a %></span>
                  <span data-test-adios><%= b %></span>
                  """
                end,
                @type_of_slot
              )
          )

        assert has_element?(view, "[data-test-hola]", "hola")
        assert has_element?(view, "[data-test-adios]", "adios")
      end
    end
  end

  describe "named slots" do
    test "displays one slot" do
      {:ok, view, _html} =
        live_isolated_component(&my_select/1,
          slots: %{
            option:
              slot(value: "5", selected: true) do
                ~H"""
                Fifth
                """
              end
          }
        )

      assert has_element?(view, "option[value=5][selected]", "Fifth")
    end

    test "displays several slots for the same name" do
      {:ok, view, _html} =
        live_isolated_component(&my_select/1,
          slots: %{
            option: [
              slot(value: "5", selected: true) do
                ~H[Fifth]
              end,
              slot(value: "10", selected: false) do
                ~H[Tenth]
              end,
              slot(value: "15", selected: false) do
                ~H[Fifteenth]
              end
            ]
          }
        )

      assert has_element?(view, "option", "Fifth")
      assert has_element?(view, "option", "Tenth")
      assert has_element?(view, "option", "Fifteenth")
    end

    test "each option can have different attributes" do
      {:ok, view, _html} =
        live_isolated_component(&my_select/1,
          slots: %{
            option: [
              slot(value: "5", selected: true) do
                ~H[Fifth]
              end,
              slot(value: "10", selected: false) do
                ~H[Tenth]
              end,
              slot(value: "15", selected: false) do
                ~H[Fifteenth]
              end
            ]
          }
        )

      assert has_element?(view, "option[value=5][selected]", "Fifth")
      assert has_element?(view, "option[value=10]:not([selected])", "Tenth")
      assert has_element?(view, "option[value=15]:not([selected])", "Fifteenth")
    end

    for {label, type_of_slot} <- [
          {"map", :map},
          {"keyword, just one value with array", :keyword_array},
          {"keyword, each item as a named pair", :keyword_multiple}
        ] do
      @label label
      @type_of_slot type_of_slot

      test "can pass items to each slot #{@label}" do
        {:ok, view, _html} =
          live_isolated_component(&table/1,
            assigns: %{
              items: [
                %{lang: "es", greeting: "hola"},
                %{lang: "en", greeting: "hello"},
                %{lang: "it", greeting: "ciao"}
              ]
            },
            slots:
              process_slot(
                [
                  slot(let: i, header: "Language") do
                    ~H"""
                    <%= i.lang %>
                    """
                  end,
                  slot(let: i, header: "Greeting") do
                    ~H"""
                    <%= i.greeting %>
                    """
                  end
                ],
                :col,
                @type_of_slot
              )
          )

        assert has_element?(view, "th[scope=col]", "Language")
        assert has_element?(view, "th[scope=col]", "Greeting")

        assert has_element?(view, "tbody tr:nth-of-type(1) td:nth-of-type(1)", "es")
        assert has_element?(view, "tbody tr:nth-of-type(1) td:nth-of-type(2)", "hola")

        assert has_element?(view, "tbody tr:nth-of-type(2) td:nth-of-type(1)", "en")
        assert has_element?(view, "tbody tr:nth-of-type(2) td:nth-of-type(2)", "hello")

        assert has_element?(view, "tbody tr:nth-of-type(3) td:nth-of-type(1)", "it")
        assert has_element?(view, "tbody tr:nth-of-type(3) td:nth-of-type(2)", "ciao")
      end
    end
  end

  defp process_slot(slots, slot_name, :map) do
    %{slot_name => slots}
  end

  defp process_slot(slots, slot_name, :keyword_array) do
    [{slot_name, slots}]
  end

  defp process_slot(slots, slot_name, :keyword_multiple) do
    Enum.map(slots, &{slot_name, &1})
  end

  defp my_select(assigns) do
    ~H"""
    <select>
      <%= for option <- @option do %>
        <option value={option.value} selected={option.selected}>
          <%= render_slot option %>
        </option>
      <% end %>
    </select>
    """
  end

  def table(assigns) do
    ~H"""
    <table>
      <thead>
        <tr>
          <%= for col <- @col do %>
            <th scope="col"><%= col.header %></th>
          <% end %>
        </tr>
      </thead>
      <tbody>
        <%= for item <- @items do %>
          <tr>
            <%= for col <- @col do %>
              <td>
                <%= render_slot col, item %>
              </td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  defp pass_value_to_default_slot(assigns) do
    ~H"""
    <%= render_slot @inner_block, @value %>
    """
  end

  defp process_slot(slot, :default), do: slot
  defp process_slot(slot, :named), do: %{inner_block: slot}
end
