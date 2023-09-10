defmodule EkmiWeb.PartnerCardComponent do
  use EkmiWeb, :live_component

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="w-full max-w-sm border rounded-lg shadow bg-gray-800 border-gray-700">
      <div class="px-4 py-6 flex flex-col items-center gap-2">
        <div class="relative inline-flex items-center justify-center w-10 h-10 overflow-hidden rounded-full bg-gray-600">
            <span class="font-medium text-gray-300">EP</span>
        </div>

        <h5 class="mb-1 text-xl font-medium text-white">
          <%= @user.email %>
        </h5>

        <span class="text-sm text-gray-400">
          <%= @user.name %>
        </span>

        <div class="flex space-x-3 mt-3">
          <%= if @user.partner_requested do %>
          <button type="button" class="text-white bg-blue-500 cursor-not-allowed font-medium rounded-lg text-sm px-5 py-2.5 text-center" disabled>Partner Requested</button>


          <% else %>
          <a
            href="#"
            class="inline-flex items-center px-4 py-2 text-sm font-medium text-center text-white rounded-lg bg-blue-600 hover:bg-blue-700"
          >
            Add as Partner
          </a>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
