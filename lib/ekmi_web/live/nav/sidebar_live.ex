defmodule EkmiWeb.Nav.SidebarLive do
  use EkmiWeb, :live_component

  alias Phoenix.LiveView.JS

  alias EkmiWeb.SVGs

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    partner_notification =
      case assigns.current_user && assigns.current_user.partner_requested && !assigns.current_user.has_partner do
        true -> 1
        nil -> nil
        false -> nil
      end

    assigns =
      assigns
      |> assign(:partner_notification, partner_notification)

    ~H"""
    <div class="relative">
      <button
        phx-click={toggle_sidebar()}
        class="absolute -top-16 sm:-top-16 -left-[20px] inline-flex items-center justify-center p-2 w-10 h-10 ml-3 text-sm rounded-lg focus:outline-none focus:ring-2 text-gray-400 focus:ring-gray-600"
        aria-controls="navbar-hamburger"
        aria-expanded="false"
        id="hamburger-btn"
      >
        <span class="sr-only">Open main menu</span>
        <SVGs.hamburger id="hamburger" />
      </button>

      <div
        id="backdrop"
        class="backdrop-sepia-0 bg-white/50 h-full w-full fixed top-0 hidden"
        phx-click={toggle_sidebar()}
      />

      <div
        id="main-sidebar"
        class="z-10 h-full sm:w-80 w-64 py-8 px-4 fixed left-0 top-0 overflow-y-auto bg-gray-800 hidden"
      >
        <button
          phx-click={toggle_sidebar()}
          type="button"
          data-drawer-hide="drawer-example"
          aria-controls="drawer-example"
          class="w-10 h-10 text-gray-400 bg-transparent rounded-lg text-sm w-8 h-8 absolute top-2.5 right-2.5 inline-flex items-center justify-center hover:bg-gray-600 hover:text-white"
        >
          <SVGs.close id="close" />
          <span class="sr-only">Close menu</span>
        </button>

        <.link navigate={~p"/budgets"} class="flex items-center pl-2.5 mb-5">
          <span class="self-center text-xl font-semibold whitespace-nowrap text-white">
            Ekmi
          </span>
        </.link>

        <ul class="space-y-2 font-medium">
          <li>
            <.link
              navigate={~p"/budgets"}
              class="flex items-center p-2 rounded-lg text-white hover:bg-gray-700 group"
            >
              <SVGs.currency id="currency" />
              <span class="ml-3">Budgets</span>
            </.link>
          </li>

          <li>
            <.link
              navigate={~p"/partners"}
              class="relative flex items-center p-2 rounded-lg text-white hover:bg-gray-700 group"
            >
              <SVGs.people id="people" />
              <span class="flex-1 ml-3 whitespace-nowrap">Partners</span>
              <%= if @partner_notification do %>
                <span class="sr-only">Notifications</span>
                <div class="absolute inline-flex items-center justify-center w-6 h-6 text-xs font-bold text-white bg-red-500 border-2 border-white rounded-full -top-2 -left-2 dark:border-gray-900">
                  <%= @partner_notification %>
                </div>
              <% end %>
            </.link>
          </li>

          <li>
            <.link
              navigate={~p"/messages"}
              class="flex items-center p-2 rounded-lg text-white hover:bg-gray-700 group"
            >
              <SVGs.message id="message" />
              <span class="flex-1 ml-3 whitespace-nowrap">Messages</span>
            </.link>
          </li>
          <li>
            <.link
              navigate={~p"/users/settings"}
              class="flex items-center p-2 rounded-lg text-white hover:bg-gray-700 group"
            >
              <SVGs.settings id="settings" />
              <span class="flex-1 ml-3 whitespace-nowrap">Settings</span>
            </.link>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  defp toggle_sidebar() do
    JS.toggle(
      to: "#main-sidebar",
      # apply css transitions or classes
      in: {
        "ease-in-out duration-300",
        "-translate-x-full",
        "-translate-x-0"
      },
      out: {
        "ease-in-out duration-300",
        "-translate-x-0",
        "-translate-x-full"
      },
      time: 300
    )
    |> JS.toggle(
      to: "#backdrop",
      in: "fade-in",
      out: "fade-out"
    )
    |> JS.toggle(
      to: "#hamburger-btn",
      in: "fade-in",
      out: "fade-out"
    )
  end

  def handle_info({:partner_requested, multi}, socket) do
    IO.puts("HELLLLO WORLDD")
    IO.inspect(multi)
    {:noreply, socket}
  end
end
