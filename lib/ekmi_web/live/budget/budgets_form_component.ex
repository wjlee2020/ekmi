defmodule EkmiWeb.BudgetsFormComponent do
  use EkmiWeb, :live_component

  alias Ekmi.Keihi
  alias Ekmi.Keihi.Budget

  @impl Phoenix.LiveComponent
  def mount(socket) do
    changeset = Keihi.change_budget(%Budget{})
   {:ok, assign(socket, budget_form: to_form(changeset))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @live_action == :new do %>
        <h1>Add a budget: JPY</h1>

        <.form
          for={@budget_form}
          class="flex flex-col gap-2 mt-2"
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <.input type="hidden" field={@budget_form[:user_id]} value={@user_id} />
          <.input label="Title" field={@budget_form[:title]} placeholder="Budget Title" autocomplete="off" />
          <.input label="Description" field={@budget_form[:description]} type="textarea" placeholder="Budget Description" autocomplete="off" />
          <.input label="Cost" field={@budget_form[:cost]} type="number" placeholder="Cost" autocomplete="off" />
          <.input label="Category" field={@budget_form[:category_id]} type="select" options={[{"Grocery/Food", 1}, {"Transportation", 2}, {"Rent", 3}, {"Utilities", 4}, {"Entertainment", 5}, {"Misc./Hobby", 6}]} />

          <.button class="mt-2">Add</.button>
        </.form>
      <% else %>
        <h1>Update</h1>

        <.form
          for={@budget_form}
          class="flex flex-col gap-2 mt-2"
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <.input label="Title" field={@budget_form[:title]} value={String.capitalize(@selected_budget.title)} placeholder="Budget Title" autocomplete="off" />
          <.input label="Description" field={@budget_form[:description]} value={@selected_budget.description} type="textarea" placeholder="Budget Description" autocomplete="off" />
          <.input label="Cost" field={@budget_form[:cost]} value={@selected_budget.cost} type="number" placeholder="Cost" autocomplete="off" />
          <.input label="Category" field={@budget_form[:category_id]} value={@selected_budget.category_id} type="select" options={[{"Grocery/Food", 1}, {"Transportation", 2}, {"Rent", 3}, {"Utilities", 4}, {"Entertainment", 5}, {"Misc./Hobby", 6}]} />

          <.button class="mt-2" phx-disable-with="Updating...">Update</.button>

          <.button
            phx-click="delete"
            phx-disable-with="Deleting..."
            phx-target={@myself}
            phx-value-id={@selected_budget.id}
            data-confirm="Are you sure?"
            class="mt-2"
          >
            <.icon name="hero-trash-solid" />
          </.button>
        </.form>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("save", %{"budget" => budget}, socket) do
    case Keihi.create_budget(budget) do
      {:ok, _budget} ->
        socket =
          socket
          |> put_flash(:info, "Added a new budget!")
          |> push_patch(to: ~p"/budgets")

        {:noreply, socket}

      {:error, changeset} ->
        budget_form =
          changeset
          |> Map.put(:action, :validate)
          |> to_form()

        socket =
          socket
          |> put_flash(:error, "Failed to create budget")
          |> assign(budget_form: budget_form)

        {:noreply, socket}
    end
  end

  def handle_event("update", %{"budget" => budget}, socket) do
    IO.inspect(budget)
    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => budget_id}, socket) do
    Keihi.delete_budget(budget_id)

    socket =
      socket
      |> put_flash(:info, "Deleted budget")
      |> push_patch(to: ~p"/budgets")
    {:noreply, socket}
  end

  def handle_event("validate", %{"budget" => budget}, socket) do
    budget_form =
      %Budget{}
      |> Keihi.change_budget(budget)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, budget_form: budget_form)}
  end
end
