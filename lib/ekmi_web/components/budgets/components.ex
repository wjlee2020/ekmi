defmodule EkmiWeb.Budgets.Components do
  @moduledoc """
  Function components for Budgets
  """

  use EkmiWeb, :html

  alias Ekmi.Cldr
  alias Ekmi.Keihi.Budget

  attr :budget, Budget, required: true
  attr :user_id, :integer, required: true

  def tiles(assigns) do
    emoji =
      case assigns.budget.category.id do
        1 -> "🍛"
        2 -> "⛽️"
        3 -> "🏠"
        4 -> "💡"
        5 -> "🌃"
        6 -> "💸"
      end

    is_current_users_budget = assigns.budget.user_id == assigns.user_id

    assigns =
      assigns
      |> assign(:emoji, emoji)
      |> assign(:is_current_users_budget, is_current_users_budget)

    ~H"""
    <div class={"
      w-full sm:w-[23rem] h-[200px] flex flex-col justify-between budget-card block
      max-w-sm p-6 border rounded-lg shadow border-gray-700 hover:bg-gray-700
      #{if @is_current_users_budget do "bg-[#111827]" else "bg-[#111827]" end}
    "}>
      <h5 class="mb-2 text-2xl font-bold tracking-tight text-white">
        <%= String.capitalize(@budget.title) %>
        <%= @emoji %>
      </h5>

      <h6 class="mb-2 text-1xl font-bold tracking-tight text-white overflow-scroll">
        <%= @budget.description %>
      </h6>

      <div class="flex justify-between gap-4">
        <p class="font-normal text-gray-400 text-end">
          <%= @budget.created_at %>
        </p>

        <p class="font-normal text-gray-400 text-end">
          <%= @budget.cost %>円
        </p>
      </div>
    </div>
    """
  end

  attr :balance, :integer, required: true
  attr :remaining_balance, :integer, required: true
  attr :class, :string, default: "flex flex-col sm:flex-row sm:gap-4"

  def monthly_balance(assigns) do
    {:ok, current_spending} = Cldr.Number.to_string(assigns.balance - assigns.remaining_balance)
    {:ok, balance} = Cldr.Number.to_string(assigns.balance)
    {:ok, remaining_balance} = Cldr.Number.to_string(assigns.remaining_balance)

    assigns =
      assigns
      |> assign(:remaining_balance, remaining_balance)
      |> assign(:balance, balance)
      |> assign(:current_spending, current_spending)
      |> assign(:class, assigns.class)

    ~H"""
    <div class={@class}>
      <span>
        Total Balance: <%= @balance %> 円
      </span>

      <span>
        Remaining Balance: <%= @remaining_balance %> 円
      </span>

      <span class="sm:ml-auto text-red-400 font-medium">
        Spent: <%= @current_spending %> 円
      </span>
    </div>
    """
  end

  attr :class, :string, default: "flex flex-col sm:flex-row sm:gap-4"
  attr :total_count, :integer, required: true
  attr :total_budget_cost, :integer, required: true

  def totals(assigns) do
    ~H"""
    <div class={@class}>
      <span>
        Total Count: <%= @total_count %>
      </span>

      <span class="sm:ml-auto text-red-400 font-medium">
        Total Cost: <%= @total_budget_cost %> 円
      </span>
    </div>
    """
  end
end
