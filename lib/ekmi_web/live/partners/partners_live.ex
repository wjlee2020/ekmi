defmodule EkmiWeb.PartnersLive do
  use EkmiWeb, :live_view

  alias Ekmi.Accounts
  alias EkmiWeb.{PartnerCardComponent, SVGs}

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:loading, false)
      |> assign(:user_email, "")
      |> assign(:user, nil)

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
        <div :if={@loading} class="px-3 py-1 text-xs font-medium leading-none text-center text-blue-800 bg-blue-200 rounded-full animate-pulse dark:bg-blue-900 dark:text-blue-200">
          loading...
        </div>

        <%= if @user do %>
          <%!-- <Components.user_card user={@user} /> --%>
          <.live_component
            module={PartnerCardComponent}
            id={:partner_card}
            user={@user}
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

  def handle_info({:run_search, user_email}, socket) do
    user = Accounts.get_user_by_email(user_email)
    IO.inspect(user)

    {:noreply, assign(socket, loading: false, user: user)}
  end
end
