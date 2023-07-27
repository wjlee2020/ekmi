defmodule EkmiWeb.Nav.SidebarLive do
  use EkmiWeb, :live_component

  alias Phoenix.LiveView.JS

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, :show_cart, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative">
      <button
        phx-click={toggle_sidebar()}
        class="absolute -top-16 sm:-top-16 sm:-left-32 inline-flex items-center justify-center p-2 w-10 h-10 ml-3 text-sm rounded-lg focus:outline-none focus:ring-2 text-gray-400 hover:bg-gray-700 focus:ring-gray-600"
        aria-controls="navbar-hamburger"
        aria-expanded="false"
      >
        <span class="sr-only">Open main menu</span>
        <svg
          class="w-5 h-5"
          aria-hidden="true"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 17 14"
        >
          <path
            stroke="currentColor"
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M1 1h15M1 7h15M1 13h15"
          />
        </svg>
      </button>

      <div
        id="backdrop"
        class={"backdrop-sepia-0 bg-white/50 h-full w-full fixed top-0 #{unless @show_cart, do: "hidden"}"}
        phx-click={toggle_sidebar()}
      />

      <div
        id="main-sidebar"
        class={"z-10 h-full w-64 py-8 px-4 fixed left-0 top-0 overflow-y-auto bg-gray-800 #{unless @show_cart, do: "hidden"}"}
      >
        <button
          phx-click={toggle_sidebar()}
          type="button"
          data-drawer-hide="drawer-example"
          aria-controls="drawer-example"
          class="w-10 h-10 text-gray-400 bg-transparent rounded-lg text-sm w-8 h-8 absolute top-2.5 right-2.5 inline-flex items-center justify-center hover:bg-gray-600 hover:text-white"
        >
          <svg
            class="w-3 h-3"
            aria-hidden="true"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 14 14"
          >
            <path
              stroke="currentColor"
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="m1 1 6 6m0 0 6 6M7 7l6-6M7 7l-6 6"
            />
          </svg>
          <span class="sr-only">Close menu</span>
        </button>

        <.link navigate={~p"/budgets"} class="flex items-center pl-2.5 mb-5">
          <%!-- <img
            src="https://flowbite.com/docs/images/logo.svg"
            class="h-6 mr-3 sm:h-7"
            alt="Flowbite Logo"
          /> --%>
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
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-6 h-6"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M2.25 18.75a60.07 60.07 0 0115.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 013 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 00-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 01-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 003 15h-.75M15 10.5a3 3 0 11-6 0 3 3 0 016 0zm3 0h.008v.008H18V10.5zm-12 0h.008v.008H6V10.5z"
                />
              </svg>

              <span class="ml-3">Budgets</span>
            </.link>
          </li>

          <li>
            <.link
              navigate={~p"/partners"}
              class="flex items-center p-2 rounded-lg text-white hover:bg-gray-700 group"
            >
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
              </svg>

              <span class="flex-1 ml-3 whitespace-nowrap">Partners</span>
            </.link>
          </li>

          <li>
            <.link
              navigate={~p"/messages"}
              class="flex items-center p-2 rounded-lg text-white hover:bg-gray-700 group"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-6 h-6"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 01.865-.501 48.172 48.172 0 003.423-.379c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0012 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018z"
                />
              </svg>
              <span class="flex-1 ml-3 whitespace-nowrap">Messages</span>
            </.link>
          </li>
          <li>
            <.link
              navigate={~p"/users/settings"}
              class="flex items-center p-2 rounded-lg text-white hover:bg-gray-700 group"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-6 h-6"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z"
                />
              </svg>

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
  end
end
