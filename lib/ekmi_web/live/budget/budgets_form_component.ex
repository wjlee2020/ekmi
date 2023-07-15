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
          <.input label="Category" field={@budget_form[:category_id]} type="select" options={[{"Grocery/Food", 1}, {"Transportation", 2}, {"Rent", 3}, {"Utilities", 4}, {"Entertainment", 5}, {"Misc./Hobby", 6}]} />
          <.input label="Cost" field={@budget_form[:cost]} type="number" placeholder="Cost" autocomplete="off" />
          <.input label="Date" field={@budget_form[:created_at]} type="date" autocomplete="off" />
          <.input label="Description" field={@budget_form[:description]} type="textarea" placeholder="Budget Description" autocomplete="off" />


          <div class="mt-3 text-sm font-medium text-gray-900 dark:text-gray-500">
            Add up to <%= @uploads.receipt_img.max_entries %> photos

            (max <%= trunc(@uploads.receipt_img.max_file_size / 1_000_000) %> MB each)
          </div>

          <.receipt_img_uploader uploads={@uploads}  />

          <.error :for={err <- upload_errors(@uploads.receipt_img)}>
            <%= Phoenix.Naming.humanize(err) %>
          </.error>

          <div class="flex flex-col gap-3">
            <div :for={entry <- @uploads.receipt_img.entries} class="flex flex-col sm:flex-row items-center gap-3">
              <.live_img_preview
                entry={entry}
                class="min-w-[16rem] h-64 rounded-lg object-cover"
              />

              <div class="w-full flex flex-col">
                <div class="flex justify-between mb-1">
                  <span class="text-sm font-medium text-blue-700">
                    <%= entry.progress%>%
                  </span>
                </div>

                <div class="w-full bg-gray-200 rounded-full h-2.5 dark:bg-gray-700">
                  <div class="bg-blue-600 h-2.5 rounded-full" style={"width: #{entry.progress}%"}></div>
                </div>

                <.error :for={err <- upload_errors(@uploads.receipt_img, entry)}>
                  <%= Phoenix.Naming.humanize(err) %>
                </.error>
              </div>

              <a
                class="cursor-pointer"
                phx-click="cancel"
                phx-value-ref={entry.ref}
                phx-target={@myself}
              >
                &times;
              </a>
            </div>
          </div>

          <.button phx-disable-with="Creating..." class="mt-2">Add</.button>
        </.form>
      <% else %>
        <h1>Update</h1>

        <.form
          for={@budget_form}
          class="flex flex-col gap-2 mt-2"
          phx-change="validate"
          phx-submit="update"
          phx-target={@myself}
        >
          <.input type="hidden" field={@budget_form[:user_id]} value={@user_id} />
          <.input type="hidden" field={@budget_form[:id]} value={@selected_budget.id} />
          <.input label="Title" field={@budget_form[:title]} value={String.capitalize(@selected_budget.title)} placeholder="Budget Title" autocomplete="off" />
          <.input label="Category" field={@budget_form[:category_id]} value={@selected_budget.category_id} type="select" options={[{"Grocery/Food", 1}, {"Transportation", 2}, {"Rent", 3}, {"Utilities", 4}, {"Entertainment", 5}, {"Misc./Hobby", 6}]} />
          <.input label="Cost" field={@budget_form[:cost]} value={@selected_budget.cost} type="number" placeholder="Cost" autocomplete="off" />
          <.input label="Date" field={@budget_form[:created_at]} value={@selected_budget.created_at} type="date" autocomplete="off" />
          <.input label="Description" field={@budget_form[:description]} value={@selected_budget.description} type="textarea" placeholder="Budget Description" autocomplete="off" />

          <div class="grid grid-cols-2 md:grid-cols-3 gap-4 mt-2">
            <div :for={ {img_location, _index} <- Enum.with_index(@selected_budget.receipt_img)}>
              <img
                class="h-64 max-w-full rounded-lg object-cover"
                src={img_location}
              />
            </div>
          </div>

          <.button class="mt-2" phx-disable-with="Loading...">Update</.button>

          <.button
            phx-click="delete"
            phx-disable-with="Loading..."
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

  attr :uploads, :map, required: true
  def receipt_img_uploader(assigns) do
    ~H"""
    <div class="flex items-center justify-center w-full" phx-drop-target={@uploads.receipt_img.ref}>
      <label for={@uploads.receipt_img.ref} class="flex flex-col items-center justify-center w-full h-36 border-2 border-gray-300 border-dashed rounded-lg cursor-pointer bg-gray-50 dark:hover:bg-bray-800 dark:bg-gray-700 hover:bg-gray-100 dark:border-gray-600 dark:hover:border-gray-500 dark:hover:bg-gray-600">
        <div class="flex flex-col items-center justify-center pt-5 pb-6">
          <svg class="w-8 h-8 mb-4 text-gray-500 dark:text-gray-400" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 20 16">
              <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 13h3a3 3 0 0 0 0-6h-.025A5.56 5.56 0 0 0 16 6.5 5.5 5.5 0 0 0 5.207 5.021C5.137 5.017 5.071 5 5 5a4 4 0 0 0 0 8h2.167M10 15V6m0 0L8 8m2-2 2 2"/>
          </svg>
          <p class="mb-2 text-sm text-gray-500 dark:text-gray-400"><span class="font-semibold">Click to upload</span> or drag and drop</p>
          <p class="text-xs text-gray-500 dark:text-gray-400">PNG, JPG or JPEG (MAX. 10MB)</p>
        </div>

        <.live_file_input
          upload={@uploads.receipt_img}
          class="hidden w-full text-sm text-gray-900 border border-gray-300 rounded-lg cursor-pointer bg-gray-50 dark:text-gray-400 focus:outline-none dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400" aria-describedby="file_input_help"
        />
      </label>
    </div>
    """
  end

  @impl true
  def handle_event("save", %{"budget" => budget}, socket) do
    receipt_img =
      consume_uploaded_entries(socket, :receipt_img, fn meta, entry ->
        dest =
          Path.join([
            "priv",
            "static",
            "uploads",
            "#{entry.uuid}-#{entry.client_name}"
          ])

        File.cp!(meta.path, dest)

        url_path = static_path(socket, "/uploads/#{Path.basename(dest)}")

        {:ok, url_path}
      end)

    budget = Map.put(budget, "receipt_img", receipt_img)

    case Keihi.create_budget(budget) do
      {:ok, _budget} ->
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

  def handle_event("cancel", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :receipt_img, ref)}
  end

  def handle_event("update", %{"budget" => budget}, socket) do
    case Keihi.update_budget(socket.assigns.selected_budget, budget) do
      {:ok, _budget} ->
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

  def handle_event("delete", %{"id" => budget_id}, socket) do
    Keihi.delete_budget(budget_id)
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
