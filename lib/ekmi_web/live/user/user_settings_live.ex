defmodule EkmiWeb.UserSettingsLive do
  use EkmiWeb, :live_view

  alias Ekmi.Accounts
  alias EkmiWeb.{Finance, UserSettings}

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your balance, email, and password</:subtitle>
    </.header>

    <div class="space-y-12 divide-y lg:w-[600px] mx-auto">
      <UserSettings.Components.name_form name_form={@name_form} />

      <Finance.Components.finance_form finance_form={@finance_form} />

      <UserSettings.Components.email_form
        email_form={@email_form}
        email_form_current_password={@email_form_current_password}
      />

      <UserSettings.Components.password_form
        password_form={@password_form}
        current_email={@current_email}
        current_password={@current_password}
        trigger_submit={@trigger_submit}
      />

      <UserSettings.Components.delete_account user_form={@user_form} />
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user_account = socket.assigns.current_user
    user_changeset = Accounts.change_delete_user(user_account)
    email_changeset = Accounts.change_user_email(user_account)
    name_change = Accounts.change_user_detail(user_account)
    password_changeset = Accounts.change_user_password(user_account)
    finance = Accounts.get_finance(%{account_id: user_account.id})
    finance_changeset = Accounts.change_finance(finance)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user_account.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:finance_form, to_form(finance_changeset))
      |> assign(:name_form, to_form(name_change))
      |> assign(:user_form, to_form(user_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("validate_balance", params, socket) do
    %{"finance" => finance_params} = params

    finance_form =
      %Accounts.Finance{}
      |> Accounts.change_finance(finance_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, finance_form: finance_form, balance: finance_params["balance"])}
  end

  def handle_event("update_balance", params, socket) do
    %{"finance" => finance_params} = params

    case Accounts.update_finance(%{
           account_id: finance_params["account_id"],
           attrs: finance_params
         }) do
      {:ok, finance} ->
        finance_changeset = Accounts.change_finance(finance)

        socket =
          socket
          |> put_flash(:info, "Updated your balance!")
          |> assign(finance_form: to_form(finance_changeset))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, finance_form: to_form(changeset))}
    end
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("update_name", %{"account" => user_params}, socket) do
    case Accounts.update_user_detail(socket.assigns.current_user, user_params) do
      {:ok, user} ->
        user_changeset = Accounts.change_user_detail(user)

        socket =
          socket
          |> put_flash(:info, "Updated user!")
          |> assign(user_form: to_form(user_changeset))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, name_form: to_form(changeset))}
    end
  end

  def handle_event("validate_name", %{"account" => user_params}, socket) do
    user_form =
      socket.assigns.current_user
      |> Accounts.change_user_detail(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, name_form: user_form)}
  end
end
