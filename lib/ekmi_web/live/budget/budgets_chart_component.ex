defmodule EkmiWeb.BudgetsChartComponent do
  @moduledoc false

  use EkmiWeb, :live_component

  alias Ekmi.{Cldr, Keihi}
  alias EkmiWeb.Budgets

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, :chart_type, :pie)}
  end

  @impl true
  def render(assigns) do
    budgets = Keihi.list_budgets(assigns.current_user)
    {total_count, total_budget_cost} = Keihi.budget_count_and_total(budgets)
    {:ok, total_budget_cost} = Cldr.Number.to_string(total_budget_cost)

    assigns =
      assigns
      |> assign(:data, contex_data(budgets))
      |> assign(:total_count, total_count)
      |> assign(:total_budget_cost, total_budget_cost)

    ~H"""
    <div class="mt-16">
      <hr class="h-px mb-16 bg-gray-200 border-0 dark:bg-gray-700" />

      <button
        phx-target={@myself}
        phx-click="toggle-chart"
        value={@chart_type}
        class="font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 bg-gray-800 text-white border-gray-600 hover:bg-gray-700 hover:border-gray-600"
      >
        Toggle
        <%= if @chart_type == :pie do %>
          Bar Chart
        <% else %>
          Pie Chart
        <% end %>
      </button>
      <div class="flex flex-col sm:flex-row">
        <%= show_graph(@chart_type, @data) %>

        <Budgets.Components.totals total_budget_cost={@total_budget_cost} total_count={@total_count} />
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("toggle-chart", %{"value" => "pie"}, socket) do
    {:noreply, assign(socket, :chart_type, :bar)}
  end

  def handle_event("toggle-chart", %{"value" => "bar"}, socket) do
    {:noreply, assign(socket, :chart_type, :pie)}
  end

  def show_graph(:pie, data) do
    dataset = Contex.Dataset.new(data, ["Category", "Cost"])

    opts = [
      mapping: %{category_col: "Category", value_col: "Cost"},
      colour_palette: [
        "fbb4ae",
        "b3cde3",
        "ccebc5",
        "decbe4",
        "fed9a6",
        "ffffcc"
      ],
      legend_setting: :legend_top,
      data_labels: true
    ]

    Contex.Plot.new(dataset, Contex.PieChart, 600, 350, opts)
    # |> Contex.Plot.titles("Finance", "Overall Usage")
    |> Contex.Plot.to_svg()
  end

  def show_graph(:bar, data) do
    dataset = Contex.Dataset.new(data, ["Category", "Cost"])

    opts = [
      mapping: %{category_col: "Category", value_cols: ["Cost"]},
      colour_palette: [
        "decbe4"
      ],
      legend_setting: :legend_top,
      data_labels: true
    ]

    Contex.Plot.new(dataset, Contex.BarChart, 600, 350, opts)
    # |> Contex.Plot.titles("Finance", "Overall Usage")
    |> Contex.Plot.to_svg()
  end

  defp contex_data(budgets) do
    budgets
    |> Enum.group_by(& &1.category.name, & &1.cost)
    |> Enum.map(fn {name, costs} ->
      total_cost = Enum.sum(costs)
      {"#{name} (#{total_cost})", total_cost}
    end)
  end
end
