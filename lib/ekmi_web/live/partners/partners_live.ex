defmodule EkmiWeb.PartnersLive do
  use EkmiWeb, :live_view

  alias Ekmi.Accounts
  alias EkmiWeb.{PartnerCardComponent, SVGs}

  def mount(_params, _session, socket) do
    if connected?(socket), do: Accounts.subscribe()

    current_user = socket.assigns.current_user

    partner =
      case current_user.requested_email do
        "" -> nil
        requested_email -> Accounts.get_user_by_email(requested_email)
      end

    socket =
      socket
      |> assign(:loading, false)
      |> assign(:user_email, "")
      |> assign(:user, partner)
      |> assign(:current_user, current_user)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <form phx-submit="search">
        <label for="default-search" class="mb-2 text-sm font-medium text-gray-900 sr-only">
          Search
        </label>

        <div class="relative">
          <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
            <SVGs.search />
          </div>

          <input
            name="user_email"
            value={@user_email}
            autofocus
            type="search"
            id="default-search"
            class="block w-full p-4 pl-10 text-sm border rounded-lg bg-gray-700 border-gray-600 placeholder-gray-400 text-white"
            placeholder="Search a user by email..."
            readonly={@loading}
            required
          />

          <button class="text-white absolute right-2.5 bottom-2.5 bg-blue-700 hover:bg-blue-800 font-medium rounded-lg text-sm px-4 py-2">
            Search
          </button>
        </div>
      </form>

      <div class="flex flex-col items-center justify-center mt-12">
        <div
          :if={@loading}
          class="px-3 py-1 text-xs font-medium leading-none text-center text-blue-800 bg-blue-200 rounded-full animate-pulse dark:bg-blue-900 dark:text-blue-200"
        >
          loading...
        </div>

        <%= if @user do %>
          <.live_component
            module={PartnerCardComponent}
            id={:partner_card}
            user={@user}
            current_user={@current_user}
          />
        <% else %>
          <span :if={!@loading}>Search for a user</span>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("search", %{"user_email" => user_email}, socket) do
    send(self(), {:run_search, user_email})
    {:noreply, assign(socket, loading: true)}
  end

  def handle_event("accept-request", _params, socket) do
    %{current_user: current_user, user: user} = socket.assigns

    case Accounts.set_partner(current_user, user) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, "Successfully Accepted Request!")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Couldn't accept request!")}
    end
  end

  def handle_info({:run_search, user_email}, socket) do
    case Accounts.get_user_by_email(user_email) do
      nil ->
        socket =
          socket
          |> assign(:loading, false)
          |> put_flash(:not_found, "User doesn't exist.")

        {:noreply, socket}

      user ->
        {:noreply, assign(socket, loading: false, user: user)}
    end
  end

  def handle_info({:run_request, request_email}, socket) do
    case Accounts.request_partner(%{
           current_user: socket.assigns.current_user,
           partner_email: request_email
         }) do
      {:ok, _} ->
        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Unable to make this request!")}
    end
  end

  def handle_info(
        {:partner_requested,
         %{update_current_user: update_current_user, update_requested_user: update_requested_user}},
        socket
      ) do
    current_user = socket.assigns.current_user

    requested_user =
      determine_requested_user(update_current_user, update_requested_user, current_user)

    current_user =
      determine_current_user(update_current_user, update_requested_user, current_user)

    socket =
      socket
      |> put_flash(:info, "Partner Requested!")
      |> assign(:user, requested_user)
      |> assign(:current_user, current_user)

    {:noreply, socket}
  end

  def handle_info({:partner_accepted, %{update_user_one: update_user_one, update_user_two: update_user_two}}, socket) do
    current_user = socket.assigns.current_user
    requested_user = determine_requested_user(update_user_one, update_user_two, current_user )
    current_user = determine_current_user(update_user_one, update_user_two, current_user)

    socket =
      socket
      |> put_flash(:info, "Partner Requested!")
      |> assign(:user, requested_user)
      |> assign(:current_user, current_user)
    {:noreply, socket}
  end

  defp determine_requested_user(update_current, update_requested, current_user)
       when update_current.email == current_user.email,
       do: update_requested

  defp determine_requested_user(update_current, _update_requested, _current_user),
    do: update_current

  defp determine_current_user(_update_current, update_requested, current_user)
       when update_requested.email == current_user.email,
       do: update_requested

  defp determine_current_user(update_current, _update_requested, _current_user),
    do: update_current
end
