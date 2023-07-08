defmodule EkmiWeb.Budgets.Components do
  use Phoenix.Component

  alias Ekmi.Keihi.Budget

  attr :budget, Budget
  def tiles(assigns) do
    ~H"""
    <div style={"--detail: #{@budget.category.id}"} class="w-[23rem]">
      <a href="#" class="h-[200px] flex flex-col justify-between budget-card block max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow hover:bg-gray-100 dark:bg-gray-800 dark:border-gray-700 dark:hover:bg-gray-700">
        <h5 class="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
          <%= @budget.title %>
        </h5>

        <h6 class="mb-2 text-1xl font-bold tracking-tight text-gray-900 dark:text-white overflow-scroll">
          <%= @budget.description %>
        </h6>

        <div class="flex justify-between gap-4">
          <p class="font-normal text-gray-700 dark:text-gray-400 text-end">
            <%= Date.to_iso8601(@budget.inserted_at) %>
          </p>

          <p class="font-normal text-gray-700 dark:text-gray-400 text-end">
            <%= @budget.cost %>円
          </p>
        </div>
      </a>
    </div>
    """
  end
end
