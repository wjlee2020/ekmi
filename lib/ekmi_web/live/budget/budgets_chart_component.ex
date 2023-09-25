defmodule EkmiWeb.BudgetsChartComponent do
  @moduledoc false

  use EkmiWeb, :live_component

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    %{inserts: budgets} = assigns.budgets

    budget_list =
      Enum.map(budgets, fn {_id, _num, budget, _nil} ->
        %{
          category: budget.category.name,
          cost: budget.cost,
          created_at: budget.created_at,
          description: budget.description
        }
      end)

    assigns = assign(assigns, :budget_list, budget_list)

    ~H"""
    <div class="mt-36">
      <hr class="h-px bg-gray-200 border-0 dark:bg-gray-700" />
      <div class="w-96">
        <canvas
          id="budget-chart"
          phx-hook="BudgetChart"
          class="mt-32"
          data-budgets={Jason.encode!(@budget_list)}
        >
        </canvas>
      </div>
    </div>
    """
  end
end
