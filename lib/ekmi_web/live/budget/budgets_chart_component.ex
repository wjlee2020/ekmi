defmodule EkmiWeb.BudgetsChartComponent do
  @moduledoc false

  use EkmiWeb, :live_component

  alias Ekmi.{Cldr, Keihi}
  alias EkmiWeb.Budgets

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    budgets = Keihi.list_budgets(assigns.current_user)
    {total_count, total_budget_cost} = Keihi.budget_count_and_total(budgets)
    {:ok, total_budget_cost} = Cldr.Number.to_string(total_budget_cost)

    data =
      budgets
      |> Enum.group_by(& &1.category.name, & &1.cost)
      |> Enum.map(fn {name, costs} ->
        total_cost = Enum.sum(costs)
        ["#{name} (#{total_cost})", total_cost]
      end)
      |> Enum.sort_by(&Enum.at(&1, 1), &>=/2)

    assigns =
      assigns
      |> assign(:data, data)
      |> assign(:total_count, total_count)
      |> assign(:total_budget_cost, total_budget_cost)

    ~H"""
    <div class="mt-36">
      <hr class="h-px mb-16 bg-gray-200 border-0 dark:bg-gray-700" />

      <div class="flex flex-col sm:flex-row">
        <%= show_graph(@data) %>

        <Budgets.Components.totals total_budget_cost={@total_budget_cost} total_count={@total_count} />
      </div>
    </div>
    """
  end

  def show_graph(data) do
    dataset = Contex.Dataset.new(data, ["Channel", "Count"])

    opts = [
      mapping: %{category_col: "Channel", value_col: "Count"},
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

    Contex.Plot.new(dataset, Contex.PieChart, 1000, 650, opts)
    |> Contex.Plot.to_svg()
  end
end
