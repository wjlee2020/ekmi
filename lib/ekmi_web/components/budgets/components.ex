defmodule EkmiWeb.Budgets.Components do
  use Phoenix.Component

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
        6 -> "𖧢"
      end

    is_current_users_budget = assigns.budget.user_id == assigns.user_id

    assigns =
      assigns
      |> assign(:emoji, emoji)
      |> assign(:is_current_users_budget, is_current_users_budget)

    ~H"""
    <div class={"
      w-full sm:w-[23rem] h-[200px] flex flex-col justify-between budget-card block
      max-w-sm p-6 border rounded-lg shadow
      #{if @is_current_users_budget do "bg-gray-800 border-gray-700 hover:bg-gray-700" else "bg-gray-800 border-gray-700 hover:bg-gray-700" end}
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

  def monthly_balance(assigns) do
    {:ok, balance} = Cldr.Number.to_string(assigns.balance)
    {:ok, remaining_balance} = Cldr.Number.to_string(assigns.remaining_balance)

    assigns =
      assigns
      |> assign(:remaining_balance, remaining_balance)
      |> assign(:balance, balance)

    ~H"""
    <div class="flex gap-4">
      <span>
        Remaining Balance: <%= @remaining_balance %> 円
      </span>

      <span>
        Total Balance: <%= @balance %> 円
      </span>
    </div>
    """
  end
end
