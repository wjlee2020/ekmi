defmodule EkmiWeb.BudgetsLive do
  @moduledoc """
  Budgets Live Module for handling all things budget related.
  """
  @moduledoc since: "1.0.0"

  use EkmiWeb, :live_view

  alias Ekmi.{Accounts, Repo}
  alias Ekmi.Keihi
  alias EkmiWeb.{Budgets, BudgetsChartComponent, BudgetsFormComponent}

  @s3_bucket "ekmi-uploads"
  @s3_region "ap-northeast-1"
  @s3_url "//#{@s3_bucket}.s3-#{@s3_region}.amazonaws.com"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket), do: Keihi.subscribe()

    current_user = socket.assigns.current_user

    socket =
      socket
      |> assign(
        username: Accounts.current_username(socket.assigns.current_user),
        user_id: socket.assigns.current_user.id
      )
      |> allow_upload(
        :receipt_img,
        accept: ~w(.png .jpeg .jpg),
        max_entries: 3,
        max_file_size: 10_000_000,
        external: &presign_upload/2
      )
      |> assign(:confirmed_user, Accounts.check_user_confirmed(current_user))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    current_user = socket.assigns.current_user
    sort_by = valid_sort_by(params)
    sort_order = valid_sort_order(params)

    page = param_to_integer(params["page"], 1)
    per_page = param_to_integer(params["per_page"], 36)

    date = Date.utc_today()

    year = param_to_integer(params["year"], date.year)
    month = param_to_integer(params["month"], date.month)

    options = %{
      sort_by: sort_by,
      sort_order: sort_order,
      page: page,
      per_page: per_page,
      year: year,
      month: month
    }

    budgets = Keihi.list_budgets_by_account(current_user, options)

    {total_count, total_budget_cost} =
      Keihi.get_budget_count_and_total(current_user, %{year: year, month: month})

    balance = Accounts.get_balance(current_user)

    remaining_balance = balance - total_budget_cost
    bal_percentage = remaining_balance / balance * 100

    socket =
      socket
      |> stream(:budgets, budgets, reset: true)
      |> assign(:selected_budget, select_budget(budgets, param_to_integer(params["id"], 0)))
      |> assign(:budgets_count, total_count)
      |> assign(:balance, balance)
      |> assign(:remaining_balance, remaining_balance)
      |> assign(:bal_percentage, bal_percentage)
      |> assign(:options, options)

    {:noreply, socket}
  end

  @impl true
  def handle_event("select-per-page", %{"per-page" => per_page}, socket) do
    params = %{socket.assigns.options | per_page: per_page}
    socket = push_patch(socket, to: ~p"/budgets?#{params}")
    {:noreply, socket}
  end

  def handle_event("filter", %{"budget_ym" => budget_ym}, socket) do
    [year, month] = String.split(budget_ym, "-")
    params = %{socket.assigns.options | year: year, month: month}

    socket = push_navigate(socket, to: ~p"/budgets?#{params}")
    {:noreply, socket}
  end

  @impl true
  def handle_info({:budget_created, budget}, socket) do
    %{options: options} = socket.assigns
    budget = budget |> Repo.preload(:category)

    socket =
      socket
      |> stream_insert(:budgets, budget, at: 0)
      |> put_flash(:info, "Created budget!")
      |> push_navigate(to: ~p"/budgets?#{options}")

    {:noreply, socket}
  end

  @impl true
  def handle_info({:budget_updated, budget}, socket) do
    budget = budget |> Repo.preload(:category)
    socket = update_remaining_balance(socket.assigns.selected_budget.cost, budget.cost, socket)

    socket =
      socket
      |> stream_insert(:budgets, budget)
      |> put_flash(:info, "Budget updated")

    {:noreply, assign(socket, live_action: :index, selected_budget: %{})}
  end

  @impl true
  def handle_info({:budget_deleted, budget}, socket) do
    %{options: options} = socket.assigns

    socket =
      socket
      |> stream_delete(:budgets, budget)
      |> put_flash(:info, "Deleted budget!")
      |> push_patch(to: ~p"/budgets?#{options}")

    {:noreply, socket}
  end

  attr :sort_by, :atom, required: true
  attr :options, :map, required: true
  slot :inner_block, required: true

  def sort_link(assigns) do
    ~H"""
    <.link
      class="px-4 w-32 text-center"
      patch={
        ~p"/budgets?#{%{@options | sort_by: @sort_by, sort_order: next_sort_order(@options.sort_order)}}"
      }
    >
      <%= render_slot(@inner_block) %>
      <%= sort_indicator(@sort_by, @options) %>
    </.link>
    """
  end

  def filter_form(assigns) do
    date = format_date(%{year: assigns.options.year, month: assigns.options.month})
    assigns = assign(assigns, :date, date)

    ~H"""
    <form phx-change="filter">
      <input class="border-0 rounded-lg" id="budget_ym" type="month" name="budget_ym" value={@date} />
    </form>
    """
  end

  def confirmed_user_add_budget(assigns) when assigns.confirmed_user do
    ~H"""
    <.link
      patch={~p"/budgets/new?#{@options}"}
      class="py-2.5 px-5 text-sm font-mediumfocus:outline-none rounded-lg border focus:z-10 focus:ring-4 focus:ring-gray-700 bg-gray-800 text-gray-200 border-gray-600 hover:text-white hover:bg-gray-700"
    >
      Add a budget
    </.link>
    """
  end

  def confirmed_user_add_budget(assigns) do
    ~H"""
    <.link
      data-confirm="You need to confirm your email before adding any budgets"
      patch={~p"/budgets"}
      class="py-2.5 px-5 text-sm font-mediumfocus:outline-none rounded-lg border focus:z-10 focus:ring-4 focus:ring-gray-700 bg-gray-800 text-gray-200 border-gray-600 hover:text-white hover:bg-gray-700"
    >
      Add a budget
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

  defp sort_indicator(column, %{sort_by: sort_by, sort_order: sort_order})
       when column == sort_by do
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

  defp valid_sort_by(_params), do: :inserted_at

  defp valid_sort_order(%{"sort_order" => sort_order}) when sort_order in ~w(asc desc) do
    String.to_atom(sort_order)
  end

  defp valid_sort_order(_params), do: :desc

  defp budget_bar_color(bal_percentage) do
    cond do
      bal_percentage > 50 -> "green"
      bal_percentage < 20 -> "red"
      bal_percentage < 50 -> "yellow"
    end
  end

  defp format_date(map) do
    year = Map.get(map, :year) |> Integer.to_string()
    month = Map.get(map, :month)

    month_string =
      if month < 10 do
        "0" <> Integer.to_string(month)
      else
        Integer.to_string(month)
      end

    "#{year}-#{month_string}"
  end

  defp presign_upload(entry, socket) do
    key = "public/#{entry.uuid}-#{entry.client_name}"

    config = %{
      region: @s3_region,
      access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID"),
      secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY")
    }

    {:ok, fields} =
      SimpleS3Upload.sign_form_upload(config, @s3_bucket,
        key: key,
        content_type: "image/png",
        max_file_size: socket.assigns.uploads.receipt_img.max_file_size,
        expires_in: :timer.hours(1)
      )

    metadata = %{
      uploader: "S3",
      key: key,
      url: @s3_url,
      fields: fields
    }

    {:ok, metadata, socket}
  end

  defp select_budget(budgets, id) when id !== 0 do
    Enum.filter(budgets, fn budget ->
      budget.id == id
    end)
    |> hd()
  end

  defp select_budget(_budgets, _id), do: %{}

  defp update_remaining_balance(initial, updated, socket) when initial !== updated do
    remaining_balance =
      case updated - initial do
        diff when diff > 0 -> socket.assigns.remaining_balance - diff
        diff when diff < 0 -> socket.assigns.remaining_balance + abs(diff)
      end

    update_bal_related(
      remaining_balance,
      remaining_balance / socket.assigns.balance * 100,
      socket
    )
  end

  defp update_remaining_balance(_, _, socket), do: socket

  defp update_bal_related(remaining_balance, bal_percentage, socket) do
    socket
    |> assign(:remaining_balance, remaining_balance)
    |> assign(:bal_percentage, bal_percentage)
  end
end
