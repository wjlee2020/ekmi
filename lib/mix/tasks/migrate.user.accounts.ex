defmodule Mix.Tasks.MigrateUserAccounts do
  use Mix.Task
  import Ecto.Query, only: [from: 2]

  @shortdoc "Migrate users table info to accounts"

  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:ekmi)

    Ekmi.Repo.transaction(fn ->
      Ekmi.Repo.all(from(u in Ekmi.Accounts.User, where: is_nil(u.account_id)))
      |> Enum.each(fn user ->
        account_attrs = %{
          name: user.name,
          partner_requested: user.partner_requested,
          has_partner: user.has_partner,
          requested_email: user.requested_email,
          requested_by: user.requested_by,
          user_id: user.id
        }

        %Ekmi.Accounts.Account{}
        |> Ekmi.Accounts.Account.changeset(account_attrs)
        |> Ekmi.Repo.insert!()
      end)
    end)
  end
end
