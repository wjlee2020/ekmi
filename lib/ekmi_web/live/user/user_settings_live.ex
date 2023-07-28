defmodule EkmiWeb.UserSettingsLive do
  use EkmiWeb, :live_view

  alias Ekmi.Accounts
  alias EkmiWeb.Finance

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your balance, email, and password</:subtitle>
    </.header>

    <div class="space-y-12 divide-y lg:w-[600px] mx-auto">
      <div>
        <.simple_form
          for={@name_form}
          id="name_form"
          phx-submit="update_name"
          phx-change="validate_name"
        >
          <.input field={@name_form[:name]} label="Name" />

          <:actions>
            <.button phx-disable-with="Changing...">Change Name</.button>
          </:actions>
        </.simple_form>
      </div>

      <Finance.Components.finance_form finance_form={@finance_form} />

      <div>
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
      </div>

      <div>
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
      </div>
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
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    name_change = Accounts.change_user_detail(user)
    password_changeset = Accounts.change_user_password(user)
    finance = Accounts.get_finance(%{user_id: user.id})
    finance_changeset = Accounts.change_finance(finance)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:finance_form, to_form(finance_changeset))
      |> assign(:name_form, to_form(name_change))
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

    IO.inspect(socket.assigns)

    case Accounts.update_finance(%{user_id: finance_params["user_id"], attrs: finance_params}) do
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

  def handle_event("update_name", %{"user" => user_params}, socket) do
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

  def handle_event("validate_name", %{"user" => user_params}, socket) do
    user_form =
      socket.assigns.current_user
      |> Accounts.change_user_detail(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, name_form: user_form)}
  end
end
