defmodule Ekmi.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Ekmi.Accounts.{Account, Finance, Partner, Queries, User, UserToken, UserNotifier}
  alias Ekmi.Repo
  alias Ekmi.Workers.FinanceWorker

  @topic inspect(__MODULE__)
  @pubsub Ekmi.PubSub

  @type ecto_changeset :: Ecto.Changeset.t()
  @type finance :: Finance.t()
  @user_not_found "Failed to find user. Please try again."

  def subscribe do
    Phoenix.PubSub.subscribe(@pubsub, @topic)
  end

  def broadcast({:ok, multi}, tag) do
    Phoenix.PubSub.broadcast(
      @pubsub,
      @topic,
      {tag, multi}
    )

    {:ok, multi}
  end

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_account_by_email(email) when is_binary(email) do
    Queries.where_user(%{email: email})
    |> Repo.one()
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  def get_all_users, do: Repo.all(User)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    user_changeset = %User{} |> User.registration_changeset(attrs)

    Multi.new()
    |> Multi.insert(:user, user_changeset)
    |> Multi.insert(:account, fn %{user: user} ->
      %Account{}
      |> Account.register_account_changeset(%{name: attrs["name"], user_id: user.id})
    end)
    |> Multi.insert(:finance, fn %{user: user} ->
      %Finance{}
      |> change_finance(%{
        balance: 100_000,
        currency: "JPY",
        scheduled_deposit_amount: 100_000,
        user_id: user.id
      })
    end)
    |> Multi.run(:oban_job, fn _repo, %{user: user} ->
      FinanceWorker.new(%{user: user})
      |> Oban.insert()
    end)
    |> Repo.transaction()
  end

  @doc """
  Deletes user with given email and password.

  ## Parameters
      - attrs: A map containing:
        - "email": The email of the user.
        - "password": The password of the user.

  ## Returns
    - {:ok, any()} - On successful deletion of the user.
    - {:error, :update_partner, changeset, %{}} - if update partner fails
    - {:error, :user, msg, %{}} - if getting a user fails
      - {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}} - Detailed error from `Ecto.Multi`.
  """
  @spec delete_user(%{required(String.t()) => String.t(), required(String.t()) => String.t()}) ::
          {:ok, any}
          | {:error, Ecto.Multi.name(), any, %{required(Ecto.Multi.name()) => any}}
  def delete_user(attrs) do
    Multi.new()
    |> Multi.run(:user, fn _repo, _changes ->
      case get_user_by_email_and_password(attrs["email"], attrs["password"]) do
        nil -> {:error, "User not found. Check your credential"}
        user -> {:ok, user}
      end
    end)
    |> Multi.run(:update_partner, fn repo, %{user: user} ->
      partner = get_partner(user)

      case partner do
        nil ->
          {:ok, nil}

        partner ->
          update_partner_change =
            User.delete_partner_changeset(partner, %{
              has_partner: false,
              partner_requested: false,
              requested_email: "",
              requested_by: ""
            })

          repo.update(User, update_partner_change)
      end
    end)
    |> Multi.delete(:delete, fn %{user: user} ->
      user
    end)
    |> Multi.delete_all(:oban_jobs, fn %{user: user} ->
      Oban.Job |> where([j], j.args["user"]["id"] == ^user.id)
    end)
    |> Repo.transaction()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  def change_user_detail(%User{} = user, attrs \\ %{}) do
    User.name_changeset(user, attrs)
  end

  def change_delete_user(%User{} = user, attrs \\ %{}) do
    User.delete_user_changeset(user, attrs)
  end

  def update_user_detail(user, attrs \\ %{}) do
    user
    |> User.name_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Multi.new()
    |> Multi.update(:user, changeset)
    |> Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Multi.new()
    |> Multi.update(:user, changeset)
    |> Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def get_user_account_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_for_account_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  @spec check_user_confirmed(User.t()) :: boolean()
  def check_user_confirmed(%{confirmed_at: nil}), do: false
  def check_user_confirmed(_user), do: true

  defp confirm_user_multi(user) do
    Multi.new()
    |> Multi.update(:user, User.confirm_changeset(user))
    |> Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Multi.new()
    |> Multi.update(:user, User.password_changeset(user, attrs))
    |> Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Finds another user by email to request being partners.

  ## Parameters
      - %{current_user: %User{]}, partner_email: String.t()}

  ## Returns
      - {:error, String.t()} - If no partner is found by their email.
      - {:ok, Multi} :: {:error, Multi.name}
  """
  def request_partner(%{current_user: current_user, partner_email: partner_email}) do
    case get_user_account_by_email(partner_email) do
      nil ->
        {:error, @user_not_found}

      _user = partner_user ->
        c_user_request_changeset =
          Account.requested_partner_changeset(current_user, %{
            partner_requested: true,
            requested_email: partner_email,
            requested_by: current_user.email
          })

        p_user_request_changeset =
          Account.requested_partner_changeset(partner_user, %{
            partner_requested: true,
            requested_email: current_user.email,
            requested_by: current_user.email
          })

        Multi.new()
        |> Multi.update(:update_current_user, c_user_request_changeset)
        |> Multi.update(:update_requested_user, p_user_request_changeset)
        |> Repo.transaction()
        |> broadcast(:partner_requested)
    end
  end

  @doc """
  Sets partner_relation for both current_user and the partner_user.

  ## Parameters
      - current_user - %User{}, the logged in user.
      - parnter_user - %User{}, the user to partner with.

  ## Returns
      - {:ok, Multi} - on success.
      - {:error, Multi.name} - should the transaction rollback.
      - {:error, String.t()} - should `partner_requested` on the given user be false.
  """
  def set_partner(current_user, partner_user) do
    with {:ok, user_one} <- is_requested_partner(current_user),
         {:ok, user_two} <- is_requested_partner(partner_user) do
      total_balance = user_one.finance.balance + user_two.finance.balance

      user_one_partner_change =
        request_partner_change(%Partner{}, %{
          account_id: user_one.id,
          partner_account_id: user_two.id,
          balance: total_balance
        })

      user_two_partner_change =
        request_partner_change(%Partner{}, %{
          account_id: user_two.id,
          partner_account_id: user_one.id,
          balance: total_balance
        })

      Multi.new()
      |> Multi.insert(:insert_partner_one, user_one_partner_change)
      |> Multi.insert(:insert_partner_two, user_two_partner_change)
      |> Multi.update(:update_user_one, fn _repo ->
        User.update_partner_changeset(user_one, %{has_partner: true})
      end)
      |> Multi.update(:update_user_two, fn _repo ->
        User.update_partner_changeset(user_two, %{has_partner: true})
      end)
      |> Repo.transaction()
      |> broadcast(:partner_accepted)
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def get_partner(%User{} = user) when user.has_partner,
    do: get_user_by_email(user.requested_email)

  def get_partner(_), do: nil

  @doc """
  Creates user's finance based on attrs.

  ## Parameters
      - `attrs`: a map that contains the finance fields.

  ## Returns
      - {:ok, %Ekmi.Accounts.Finance{}} if successful.
      - {:error, %Ecto.Changeset{}} if errored.

  ## Examples
      iex> Ekmi.Accounts.create_finance(%{balance: 100000, currency: "JPY", scheduled_deposit_amount: 100000})
      {:ok, %Ekmi.Accounts.Finance{}}
  """
  @spec create_finance(map()) :: {:ok, finance()} | {:error, ecto_changeset()}
  def create_finance(attrs) do
    %Finance{}
    |> change_finance(attrs)
    |> Repo.insert()
  end

  @doc """
  Grabs user finance and updates according to the given `attrs`.

  ## Parameters
      - `user_id` - integer which represents the user id.
      - `attrs` - map containing the finance fields to update.

  ## Returns
      - `{:ok, %Ekmi.Accounts.Finance{}}` on success.
      - `{:error, Ecto.Changeset}` on error.

  ## Examples
      iex> Ekmi.Accounts.update_finance(%{user_id: 1, attrs: %{balance: 100000}})
      {:ok, %Ekmi.Accounts.Finance{}}

  """
  def update_finance(%{account_id: account_id, attrs: attrs}) do
    get_finance(%{account_id: account_id})
    |> change_finance(attrs)
    |> Repo.update()
  end

  def update_finance(%Account{} = account, attrs) do
    account = Repo.preload(account, :partner_relation)

    Multi.new()
    |> Multi.update(:update_user_balance, fn _repo ->
      get_finance(%{account_id: account.id})
      |> change_finance(attrs)
    end)
    |> Multi.update(:update_partner_rel_balance, fn _repo ->
      request_partner_change(account.partner_relation, attrs)
    end)
  end

  @doc """
  Grabs finance based on user id and updates by adding to the balance, its scheduled deposit amount.

  ## Parameters
      - `user_id` - integer which represents the user id.

  ## Returns
      - {:ok, %Ekmi.Accounts.Finance{}} on success.
      - {:error, Ecto.Changeset} on error.

  ## Example
      iex> Ekmi.Accounts.update_balance_by_scheduled_deposit_amount(1)
      {:ok, %Ekmi.Accounts.Finance{}}

  """
  @spec update_balance_by_scheduled_deposit_amount(integer()) ::
          {:ok, finance()} | {:error, ecto_changeset()}
  def update_balance_by_scheduled_deposit_amount(account_id) do
    finance = get_finance(%{account_id: account_id})
    new_balance = finance.balance + finance.scheduled_deposit_amount

    finance
    |> Finance.balance_changeset(%{balance: new_balance})
    |> Repo.update()
  end

  @doc """
  Grabs user finance based on given user id else returns nil.

  ## Parameters
      - `user_id` - integer which represents the user id.

  ## Returns
      - %Ekmi.Accounts.Finance{} if found.
      - nil if no finance found for the user.

  """
  @spec get_finance(%{:account_id => integer()}) :: finance() | term()
  def get_finance(%{account_id: account_id}) do
    Repo.get_by!(Finance, account_id: account_id)
  end

  @doc """
  Grabs user finance balance.

  ## Parameters
      - %Ekmi.Accounts.User{} - the user struct pertaining to the balance.

  ## Returns
      - `balance` - integer representing the user current balance.
          - if user has a partner, it returns the partner_relation finance balance

  """
  @spec get_balance(Account.t()) :: integer()
  def get_balance(%Account{} = account) do
    case account.has_partner do
      true ->
        %{partner_relation: %{balance: balance}} = Repo.preload(account, :partner_relation)
        balance

      false ->
        get_finance(%{account_id: account.id}).balance
    end
  end

  def change_finance(%Finance{} = finance, attr \\ %{}) do
    Finance.changeset(finance, attr)
  end

  def request_partner_change(%Partner{} = partner, attr \\ %{}) do
    Partner.changeset(partner, attr)
  end

  @doc """
  Grabs the user name if it exists. Otherwise, splits the user email at "@" and returns the hd().

  ## Parameter
      - `current_user` - current user in the `conn`.

  ## Returns
      - `current_user.name` - if `name` exist.
      - `current_user.email` - split at "@", returning the hd().

  """
  def current_username(current_user) do
    current_user.name ||
      current_user.email
      |> String.split("@")
      |> hd()
  end

  defp is_requested_partner(%{partner_requested: partner_requested} = account) do
    case partner_requested do
      true ->
        account = Repo.preload(account, [:finance, :partner_relation])
        {:ok, account}

      false ->
        {:error, "#{account.email} has no partner reqeusted"}
    end
  end
end
