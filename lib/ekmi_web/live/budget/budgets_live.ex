defmodule EkmiWeb.BudgetsLive do
  @moduledoc """
  Budgets Live Module for handling all things budget related.
  """
  @moduledoc since: "1.0.0"

  use EkmiWeb, :live_view

  @s3_bucket "ekmi-uploads"
  @s3_url "//#{@s3_bucket}.s3.amazonaws.com"
  @s3_region "ap-northeast-1"

  alias Ekmi.{Accounts, Repo}
  alias Ekmi.Keihi
  alias EkmiWeb.{Budgets, BudgetsChartComponent, BudgetsFormComponent}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket), do: Keihi.subscribe()

    [username, _domain] = String.split(socket.assigns.current_user.email, "@")

    socket =
      assign(socket,
        username: String.capitalize(username),
        user_id: socket.assigns.current_user.id
      )

    socket =
      socket
      |> assign(username: String.capitalize(username), user_id: socket.assigns.current_user.id)
      |> allow_upload(
        :receipt_img,
        accept: ~w(.png .jpeg .jpg),
        max_entries: 3,
        max_file_size: 10_000_000,
        external: &presign_upload/2
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    user_id = socket.assigns.current_user.id
    sort_by = valid_sort_by(params)
    sort_order = valid_sort_order(params)

    page = param_to_integer(params["page"], 1)
    per_page = param_to_integer(params["per_page"], 9)

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

    selected_budget =
      case Keihi.find_budget(user_id, param_to_integer(params["id"], 0)) do
        nil -> %{}
        budget -> budget
      end

    budgets = Keihi.list_budgets(%{user_id: user_id}, options)
    total_budget_cost = Keihi.get_total_budget_cost(%{user_id: user_id})
    finance = Accounts.get_finance(%{user_id: socket.assigns.current_user.id})
    balance = finance.balance
    remaining_balance = balance - total_budget_cost
    bal_percentage = remaining_balance / balance * 100

    socket =
      socket
      |> stream(:budgets, budgets)
      |> assign(:selected_budget, selected_budget)
      |> assign(:budgets_count, Keihi.budgets_count())
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
    budget = budget |> Repo.preload(:category)

    socket =
      socket
      |> stream_insert(:budgets, budget, at: 0)
      |> put_flash(:info, "Created budget!")
      |> push_navigate(to: ~p"/budgets")

    {:noreply, socket}
  end

  @impl true
  def handle_info({:budget_updated, budget}, socket) do
    budget = budget |> Repo.preload(:category)

    socket =
      socket
      |> stream_insert(:budgets, budget)
      |> put_flash(:info, "Budget updated")
      |> push_navigate(to: ~p"/budgets")

    {:noreply, socket}
  end

  @impl true
  def handle_info({:budget_deleted, budget}, socket) do
    socket =
      socket
      |> stream_delete(:budgets, budget)
      |> put_flash(:info, "Deleted budget!")
      |> push_patch(to: ~p"/budgets")

    {:noreply, socket}
  end

  attr :sort_by, :atom, required: true
  attr :options, :map, required: true
  slot :inner_block, required: true

  def sort_link(assigns) do
    ~H"""
    <.link
      class="px-4 w-32 text-center"
      navigate={
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
    config = %{
      region: @s3_region,
      access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID"),
      secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY")
    }

    {:ok, fields} =
      SimpleS3Upload.sign_form_upload(config, "my-bucket",
        key: "public/my-file-name",
        content_type: "image/png",
        max_file_size: 10_000,
        expires_in: :timer.hours(1)
      )

    metadata = %{
      uploader: "S3",
      key: "#{entry.uuid}-#{entry.client_name}",
      url: @s3_url,
      fields: fields
    }

    {:ok, metadata, socket}
  end
end
