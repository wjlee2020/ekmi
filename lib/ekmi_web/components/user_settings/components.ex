defmodule EkmiWeb.UserSettings.Components do
  @moduledoc """
  Function components for User Settings
  """

  use EkmiWeb, :html

  def name_form(assigns) do
    ~H"""
    <.simple_form for={@name_form} id="name_form" phx-submit="update_name" phx-change="validate_name">
      <.input field={@name_form[:name]} label="Name" />

      <:actions>
        <.button phx-disable-with="Changing...">Change Name</.button>
      </:actions>
    </.simple_form>
    """
  end

  def email_form(assigns) do
    ~H"""
    <.simple_form
      for={@email_form}
      id="email_form"
      phx-submit="update_email"
      phx-change="validate_email"
    >
      <.input field={@email_form[:email]} type="email" label="Email" required />
      <.input
        field={@email_form[:current_password]}
        name="current_password"
        id="current_password_for_email"
        type="password"
        label="Current password"
        value={@email_form_current_password}
        required
      />
      <:actions>
        <.button phx-disable-with="Changing...">Change Email</.button>
      </:actions>
    </.simple_form>
    """
  end

  def password_form(assigns) do
    ~H"""
    <.simple_form
      for={@password_form}
      id="password_form"
      action={~p"/users/log_in?_action=password_updated"}
      method="post"
      phx-change="validate_password"
      phx-submit="update_password"
      phx-trigger-action={@trigger_submit}
    >
      <.input
        field={@password_form[:email]}
        type="hidden"
        id="hidden_user_email"
        value={@current_email}
      />
      <.input field={@password_form[:password]} type="password" label="New password" required />
      <.input
        field={@password_form[:password_confirmation]}
        type="password"
        label="Confirm new password"
      />
      <.input
        field={@password_form[:current_password]}
        name="current_password"
        type="password"
        label="Current password"
        id="current_password_for_password"
        value={@current_password}
        required
      />
      <:actions>
        <.button phx-disable-with="Changing...">Change Password</.button>
      </:actions>
    </.simple_form>
    """
  end

  def delete_account(assigns) do
    ~H"""
    <.simple_form for={@user_form} id="user_form" method="delete" action={~p"/users/delete"}>
      <.input id={:delete_account_email} field={@user_form[:email]} label="Email" required />
      <.input
        id={:delete_account_pw}
        type="password"
        field={@user_form[:password]}
        label="Password"
        required
      />

      <:actions>
        <.button
          destructive={true}
          phx-disable-with="Deleting"
          class="bg-red-700 hover:bg-red-400"
          data-confirm="This will delete all your records and your account. Continue?"
        >
          Delete
        </.button>
      </:actions>
    </.simple_form>
    """
  end
end
