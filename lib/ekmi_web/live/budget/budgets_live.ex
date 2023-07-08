defmodule EkmiWeb.BudgetsLive do
  use EkmiWeb, :live_view

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
    per_page = param_to_integer(params["per_page"], 10)

    options = %{sort_by: sort_by, sort_order: sort_order, page: page, per_page: per_page}

    budgets = Keihi.list_budgets(%{user_id: socket.assigns.current_user.id}, options)
    socket = assign(socket, budgets: budgets, options: options, budgets_count: Keihi.budgets_count())

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="text-3xl font-bold">Hello <%= @username %>!</h1>

    <hr class="h-px my-8 bg-gray-200 border-0 dark:bg-gray-700">

    <div class="flex items-center gap-4">
      <.sort_link sort_by={:category_id} options={@options}>
        Category
      </.sort_link>

      <.sort_link sort_by={:cost} options={@options}>
        Cost
      </.sort_link>

      <.sort_link sort_by={:inserted_at} options={@options}>
        Created
      </.sort_link>

      <form class="ml-auto" phx-change="select-per-page">
        <select class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm text-center inline-flex items-center dark:bg-blue-700 dark:hover:bg-blue-900 dark:focus:ring-blue-900" name="per-page">
          <%= Phoenix.HTML.Form.options_for_select(
            [10, 15, 20, 25],
            @options.per_page
          ) %>
        </select>

        <label for="per-page">Per-Page</label>
      </form>
    </div>

    <div class="py-4 flex flex-wrap gap-2">
      <div :for={budget <- @budgets}>
        <Budgets.Components.tiles budget={budget} />
      </div>
    </div>

    <div class="flex items-center gap-2">
      <.link :if={@options.page > 1} class="flex items-center justify-center px-3 h-8 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-lg hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white" patch={~p"/budgets?#{%{@options | page: @options.page - 1}}"}>
        Prev
      </.link>

      <.link
        :if={more_pages?(@options, @budgets_count)}
        :for={{page_number, current_page?} <- pages(@options, @budgets_count)}
        class={if current_page?, do: "active"}
        patch={~p"/budgets?#{%{@options | page: page_number}}"}
      >
        <%= page_number %>
      </.link>

      <.link :if={more_pages?(@options, @budgets_count)} class="flex items-center justify-center px-3 h-8 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-lg hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white" patch={~p"/budgets?#{%{@options | page: @options.page + 1}}"}>
        Next
      </.link>
    </div>
    """
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
