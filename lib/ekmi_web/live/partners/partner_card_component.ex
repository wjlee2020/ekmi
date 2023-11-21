defmodule EkmiWeb.PartnerCardComponent do
  @moduledoc false

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
          <%= case button_type(@user, @current_user.email) do %>
            <% :partner_accepted -> %>
              <button
                class="text-white bg-blue-500 cursor-not-allowed font-medium rounded-lg text-sm px-5 py-2.5 text-center"
                disabled
              >
                Partnered
              </button>
            <% :partner_requested -> %>
              <button
                class="text-white bg-blue-500 cursor-not-allowed font-medium rounded-lg text-sm px-5 py-2.5 text-center"
                disabled
              >
                Partner Requested
              </button>
            <% :accept_request -> %>
              <button
                class="text-white font-medium rounded-lg text-sm px-5 py-2.5 bg-blue-600 hover:bg-blue-700"
                phx-click="accept-request"
              >
                Accept Request
              </button>
            <% :request_partner -> %>
              <button
                class="text-white font-medium rounded-lg text-sm px-5 py-2.5 bg-blue-600 hover:bg-blue-700"
                value={@user.email}
                phx-target={@myself}
                phx-click="request"
              >
                Request Partner
              </button>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("request", %{"value" => request_email}, socket) do
    send(self(), {:run_request, request_email})
    {:noreply, socket}
  end

  defp button_type(
         %{partner_requested: true, has_partner: true, requested_by: _email},
         _current_user_email
       ) do
    :partner_accepted
  end

  defp button_type(
         %{partner_requested: true, has_partner: false, requested_by: email},
         current_user_email
       )
       when email == current_user_email do
    :partner_requested
  end

  defp button_type(%{partner_requested: true, has_partner: false}, _current_user_email) do
    :accept_request
  end

  defp button_type(_, _) do
    :request_partner
  end
end
