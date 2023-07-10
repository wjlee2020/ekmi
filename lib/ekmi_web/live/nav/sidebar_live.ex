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
        class="fixed top-8 left-8 inline-flex items-center justify-center p-2 w-10 h-10 ml-3 text-sm text-gray-500 rounded-lg hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-200 dark:text-gray-400 dark:hover:bg-gray-700 dark:focus:ring-gray-600" aria-controls="navbar-hamburger" aria-expanded="false"
      >
        <span class="sr-only">Open main menu</span>
        <svg class="w-5 h-5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 17 14">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M1 1h15M1 7h15M1 13h15"/>
        </svg>
      </button>

      <div
        id="backdrop"
        class={"backdrop-sepia-0 bg-white/50 h-full w-full fixed top-0 #{unless @show_cart, do: "hidden"}"}
        phx-click={toggle_sidebar()}
      />

      <div
        id="main-sidebar"
        class={"h-full w-64 py-8 px-4 fixed left-0 top-0 overflow-y-auto bg-gray-50 dark:bg-gray-800 #{unless @show_cart, do: "hidden"}"}
      >
        <button
          phx-click={toggle_sidebar()}
          type="button"
          data-drawer-hide="drawer-example"
          aria-controls="drawer-example"
          class="w-10 h-10 text-gray-400 bg-transparent hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm w-8 h-8 absolute top-2.5 right-2.5 inline-flex items-center justify-center dark:hover:bg-gray-600 dark:hover:text-white"
        >
          <svg class="w-3 h-3" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 14 14">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m1 1 6 6m0 0 6 6M7 7l6-6M7 7l-6 6"/>
          </svg>
          <span class="sr-only">Close menu</span>
        </button>

        <.link navigate={~p"/budgets"} class="flex items-center pl-2.5 mb-5">
          <img src="https://flowbite.com/docs/images/logo.svg" class="h-6 mr-3 sm:h-7" alt="Flowbite Logo" />
          <span class="self-center text-xl font-semibold whitespace-nowrap dark:text-white">Ekmi</span>
        </.link>

        <ul class="space-y-2 font-medium">
          <li>
            <.link navigate={~p"/budgets"} class="flex items-center p-2 text-gray-900 rounded-lg dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700 group">
              <svg class="w-5 h-5 text-gray-500 transition duration-75 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-white" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 22 21">
                <path d="M16.975 11H10V4.025a1 1 0 0 0-1.066-.998 8.5 8.5 0 1 0 9.039 9.039.999.999 0 0 0-1-1.066h.002Z"/>
                <path d="M12.5 0c-.157 0-.311.01-.565.027A1 1 0 0 0 11 1.02V10h8.975a1 1 0 0 0 1-.935c.013-.188.028-.374.028-.565A8.51 8.51 0 0 0 12.5 0Z"/>
              </svg>
              <span class="ml-3">Budgets</span>
            </.link>
          </li>
          <li>
            <.link navigate={~p"/"} class="flex items-center p-2 text-gray-900 rounded-lg dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700 group">
              <svg class="flex-shrink-0 w-5 h-5 text-gray-500 transition duration-75 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-white" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">
                <path d="m17.418 3.623-.018-.008a6.713 6.713 0 0 0-2.4-.569V2h1a1 1 0 1 0 0-2h-2a1 1 0 0 0-1 1v2H9.89A6.977 6.977 0 0 1 12 8v5h-2V8A5 5 0 1 0 0 8v6a1 1 0 0 0 1 1h8v4a1 1 0 0 0 1 1h2a1 1 0 0 0 1-1v-4h6a1 1 0 0 0 1-1V8a5 5 0 0 0-2.582-4.377ZM6 12H4a1 1 0 0 1 0-2h2a1 1 0 0 1 0 2Z"/>
              </svg>
              <span class="flex-1 ml-3 whitespace-nowrap">Chat</span>
              <span class="inline-flex items-center justify-center w-3 h-3 p-3 ml-3 text-sm font-medium text-blue-800 bg-blue-100 rounded-full dark:bg-blue-900 dark:text-blue-300">3</span>
            </.link>
          </li>
          <li>
            <.link navigate={~p"/users/settings"} class="flex items-center p-2 text-gray-900 rounded-lg dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700 group">
              <svg class="flex-shrink-0 w-5 h-5 text-gray-500 transition duration-75 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-white" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 18">
                <path d="M14 2a3.963 3.963 0 0 0-1.4.267 6.439 6.439 0 0 1-1.331 6.638A4 4 0 1 0 14 2Zm1 9h-1.264A6.957 6.957 0 0 1 15 15v2a2.97 2.97 0 0 1-.184 1H19a1 1 0 0 0 1-1v-1a5.006 5.006 0 0 0-5-5ZM6.5 9a4.5 4.5 0 1 0 0-9 4.5 4.5 0 0 0 0 9ZM8 10H5a5.006 5.006 0 0 0-5 5v2a1 1 0 0 0 1 1h11a1 1 0 0 0 1-1v-2a5.006 5.006 0 0 0-5-5Z"/>
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
