defmodule EkmiWeb.UserSessionController do
  use EkmiWeb, :controller

  alias Ekmi.Accounts
  alias EkmiWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(
      conn,
      params,
      "Account created successfully! Please check your email for a confirmation link."
    )
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  def delete(conn, %{"user" => user_params}) do
    case Accounts.delete_user(user_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Deleted account successfully.")
        |> UserAuth.log_out_user()

      {:error, :user, msg, _} ->
        conn
        |> put_flash(:error, msg)
        |> redirect(to: ~p"/users/settings")

      {:error, :update_partner, _, _changeset} ->
        conn
        |> put_flash(:error, "Failed to delete. Please try again.")
        |> redirect(to: ~p"/users/settings")

      {:error, _, _, _} ->
        conn
        |> put_flash(:error, "Unable to delete account. Check your password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
