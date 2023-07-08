defmodule EkmiWeb.BudgetsLive do
  use EkmiWeb, :live_view

  alias Ekmi.Accounts
  alias Ekmi.Keihi
  alias EkmiWeb.Budgets

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    [username, _domain] = String.split(socket.assigns.current_user.email, "@")
    socket = assign(socket, username: String.capitalize(username))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    sort_by = valid_sort_by(params)
    sort_order = valid_sort_order(params)

    page = param_to_integer(params["page"], 1)
    per_page = param_to_integer(params["per_page"], 9)

    options = %{sort_by: sort_by, sort_order: sort_order, page: page, per_page: per_page}

    budgets = Keihi.list_budgets(%{user_id: socket.assigns.current_user.id}, options)
    finance = Accounts.get_finance(%{user_id: socket.assigns.current_user.id})
    total_budget_cost = Enum.reduce(budgets, 0, fn budget, acc -> acc + budget.cost end)
    remaining_balance = finance.balance - total_budget_cost
    socket = assign(socket, budgets: budgets, options: options, budgets_count: Keihi.budgets_count(), balance: finance.balance, remaining_balance: remaining_balance)

    {:noreply, socket}
  end

  @impl true
  def handle_event("select-per-page", %{"per-page" => per_page}, socket) do
    params = %{socket.assigns.options | per_page: per_page}
    socket = push_patch(socket, to: ~p"/budgets?#{params}")
    {:noreply, socket}
  end

  attr :sort_by, :atom, required: true
  attr :options, :map, required: true
  slot :inner_block, required: true
  def sort_link(assigns) do
    ~H"""
    <.link class="px-4 w-32 text-center" patch={~p"/budgets?#{%{@options | sort_by: @sort_by, sort_order: next_sort_order(@options.sort_order)}}"}>
      <%= render_slot(@inner_block) %>
      <%= sort_indicator(@sort_by, @options) %>
    </.link>
    """
  end

  defp more_pages?(options, budgets_count) do
    options.page * options.per_page < budgets_count
  end

  defp next_sort_order(sort_order) do
    case sort_order do
      :asc -> :desc
      :desc -> :asc
    end
  end

  defp pages(options, budgets_count) do
    page_count = ceil(budgets_count / options.per_page)

    for page_number <- (options.page - 2)..(options.page + 2),
        page_number > 0 do
      if page_number <= page_count do
        current_page? = page_number == options.page
        {page_number, current_page?}
      end
    end
  end

  defp sort_indicator(column, %{sort_by: sort_by, sort_order: sort_order}) when column == sort_by do
    case sort_order do
      :asc -> "⬆️"
      :desc -> "⬇️"
    end
  end

  defp sort_indicator(_, _), do: ""

  defp param_to_integer(nil, default), do: default
  defp param_to_integer(param, default) do
    case Integer.parse(param) do
      {number, _} ->
        number

      :error ->
        default
    end
  end

  defp valid_sort_by(%{"sort_by" => sort_by}) when sort_by in ~w(category_id cost inserted_at) do
    String.to_atom(sort_by)
  end
  defp valid_sort_by(_params), do: :id

  defp valid_sort_order(%{"sort_order" => sort_order}) when sort_order in ~w(asc desc) do
    String.to_atom(sort_order)
  end
  defp valid_sort_order(_params), do: :asc
end
