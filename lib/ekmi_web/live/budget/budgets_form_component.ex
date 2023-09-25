defmodule EkmiWeb.BudgetsFormComponent do
  @moduledoc false

  use EkmiWeb, :live_component

  alias Ekmi.{Keihi, Repo}
  alias Ekmi.Keihi.Budget
  alias EkmiWeb.SVGs

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
          phx-change="validate_new"
          phx-submit="save"
          phx-target={@myself}
        >
          <.input type="hidden" field={@budget_form[:user_id]} value={@user_id} />
          <.input
            label="Title"
            field={@budget_form[:title]}
            placeholder="Budget Title"
            autocomplete="off"
          />
          <.input
            label="Category"
            field={@budget_form[:category_id]}
            type="select"
            options={[
              {"Grocery/Food", 1},
              {"Transportation", 2},
              {"Rent", 3},
              {"Utilities", 4},
              {"Entertainment", 5},
              {"Misc./Hobby", 6}
            ]}
          />
          <.input
            label="Cost"
            field={@budget_form[:cost]}
            type="number"
            placeholder="Cost"
            autocomplete="off"
          />
          <.input label="Date" field={@budget_form[:created_at]} type="date" autocomplete="off" />
          <.input
            label="Description"
            field={@budget_form[:description]}
            type="textarea"
            placeholder="Budget Description"
            autocomplete="off"
          />

          <div class="mt-3 text-sm font-medium text-gray-500">
            Add up to <%= @uploads.receipt_img.max_entries %> photos

            (max <%= trunc(@uploads.receipt_img.max_file_size / 1_000_000) %> MB each)
          </div>

          <.receipt_img_uploader uploads={@uploads} />

          <.error :for={err <- upload_errors(@uploads.receipt_img)}>
            <%= Phoenix.Naming.humanize(err) %>
          </.error>

          <div class="flex flex-col gap-3">
            <div
              :for={entry <- @uploads.receipt_img.entries}
              class="flex flex-col sm:flex-row items-center gap-3"
            >
              <.live_img_preview entry={entry} class="min-w-[16rem] h-64 rounded-lg object-cover" />

              <div class="w-full flex flex-col">
                <div class="flex justify-between mb-1">
                  <span class="text-sm font-medium text-blue-700">
                    <%= entry.progress %>%
                  </span>
                </div>

                <div class="w-full rounded-full h-2.5 bg-gray-700">
                  <div class="bg-blue-600 h-2.5 rounded-full" style={"width: #{entry.progress}%"}>
                  </div>
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
          <.input
            label="Title"
            field={@budget_form[:title]}
            value={String.capitalize(@selected_budget.title)}
            placeholder="Budget Title"
            autocomplete="off"
          />
          <.input
            label="Category"
            field={@budget_form[:category_id]}
            value={@selected_budget.category_id}
            type="select"
            options={[
              {"Grocery/Food", 1},
              {"Transportation", 2},
              {"Rent", 3},
              {"Utilities", 4},
              {"Entertainment", 5},
              {"Misc./Hobby", 6}
            ]}
          />
          <.input
            label="Cost"
            field={@budget_form[:cost]}
            value={@selected_budget.cost}
            type="number"
            placeholder="Cost"
            autocomplete="off"
          />
          <.input
            label="Date"
            field={@budget_form[:created_at]}
            value={@selected_budget.created_at}
            type="date"
            autocomplete="off"
          />
          <.input
            label="Description"
            field={@budget_form[:description]}
            value={@selected_budget.description}
            type="textarea"
            placeholder="Budget Description"
            autocomplete="off"
          />

          <div class="mt-3 text-sm font-medium text-gray-500">
            Add up to <%= @uploads.receipt_img.max_entries %> photos

            (max <%= trunc(@uploads.receipt_img.max_file_size / 1_000_000) %> MB each)
          </div>

          <.receipt_img_uploader uploads={@uploads} />

          <.error :for={err <- upload_errors(@uploads.receipt_img)}>
            <%= Phoenix.Naming.humanize(err) %>
          </.error>

          <div class="grid grid-cols-2 md:grid-cols-3 gap-4 mt-2">
            <div
              :for={{img_location, index} <- Enum.with_index(@selected_budget.receipt_img)}
              class="relative"
            >
              <img class="h-64 max-w-full rounded-lg object-cover" src={img_location} />

              <a
                class="absolute -top-4 -right-2 text-2xl font-bold cursor-pointer hover:text-red-400"
                phx-click="remove_img"
                phx-value-ref={index}
                phx-target={@myself}
              >
                &times;
              </a>
            </div>
          </div>

          <div class="flex flex-col gap-3">
            <div
              :for={entry <- @uploads.receipt_img.entries}
              class="flex flex-col sm:flex-row items-center gap-3"
            >
              <.live_img_preview entry={entry} class="min-w-[16rem] h-64 rounded-lg object-cover" />

              <div class="w-full flex flex-col">
                <div class="flex justify-between mb-1">
                  <span class="text-sm font-medium text-blue-700">
                    <%= entry.progress %>%
                  </span>
                </div>

                <div class="w-full rounded-full h-2.5 bg-gray-700">
                  <div class="bg-blue-600 h-2.5 rounded-full" style={"width: #{entry.progress}%"}>
                  </div>
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
      <label
        for={@uploads.receipt_img.ref}
        class="flex flex-col items-center justify-center w-full h-36 border-2 border-dashed rounded-lg cursor-pointer bg-gray-700 border-gray-600 hover:border-gray-500 hover:bg-gray-600"
      >
        <div class="flex flex-col items-center justify-center pt-5 pb-6">
          <SVGs.img_uploader id="img_uploader" />

          <p class="mb-2 text-sm text-gray-500 dark:text-gray-400">
            <span class="font-semibold">Click to upload</span> or drag and drop
          </p>
          <p class="text-xs text-gray-500 dark:text-gray-400">PNG, JPG or JPEG (MAX. 10MB)</p>
        </div>

        <.live_file_input
          upload={@uploads.receipt_img}
          class="hidden w-full text-sm border rounded-lg cursor-pointer text-gray-400 focus:outline-none bg-gray-700 border-gray-600 placeholder-gray-400"
          aria-describedby="file_input_help"
        />
      </label>
    </div>
    """
  end

  @impl true
  def handle_event("save", %{"budget" => budget}, socket) do
    receipt_img = consume_receipt_img(socket)

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

  def handle_event("remove_img", %{"ref" => ref}, socket) do
    index = String.to_integer(ref)
    current_images = socket.assigns.selected_budget.receipt_img
    updated_images = List.delete_at(current_images, index)
    updated_budget = %{socket.assigns.selected_budget | receipt_img: updated_images}
    {:noreply, assign(socket, selected_budget: updated_budget)}
  end

  def handle_event("cancel", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :receipt_img, ref)}
  end

  def handle_event("update", %{"budget" => budget}, socket) do
    original_budget = Repo.get(Budget, budget["id"])

    receipt_img = consume_receipt_img(socket)

    struct_map = Map.from_struct(socket.assigns.selected_budget)

    string_key_struct_map =
      struct_map
      |> Enum.map(fn {k, v} -> {to_string(k), v} end)
      |> Enum.into(%{})

    string_key_struct_map = %{
      string_key_struct_map
      | "cost" => budget["cost"],
        "category_id" => budget["category_id"],
        "created_at" => budget["created_at"],
        "description" => budget["description"],
        "id" => budget["id"],
        "title" => budget["title"],
        "user_id" => budget["user_id"],
        "receipt_img" => socket.assigns.selected_budget.receipt_img ++ receipt_img
    }

    case Keihi.update_budget(original_budget, string_key_struct_map) do
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

  def handle_event("validate_new", %{"budget" => budget}, socket) do
    budget_form =
      %Budget{}
      |> Keihi.change_budget(budget)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, budget_form: budget_form)}
  end

  def handle_event("validate", %{"budget" => budget}, socket) do
    budget_form =
      socket.assigns.selected_budget
      |> Keihi.change_budget(budget)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply,
     assign(socket,
       budget_form: budget_form,
       selected_budget: %Budget{
         socket.assigns.selected_budget
         | cost: budget["cost"],
           category_id: budget["category_id"],
           description: budget["description"],
           title: budget["title"],
           user_id: budget["user_id"]
       }
     )}
  end

  defp consume_receipt_img(socket) do
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
  end
end
