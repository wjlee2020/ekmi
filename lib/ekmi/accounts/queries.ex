defmodule Ekmi.Accounts.Queries do
  @moduledoc """
  Queries for accounts and users
  """

  import Ecto.Query
  alias Ekmi.Accounts.{Account, User}

  def where_user(%{email: email}) do
    from a in Account,
      join: u in User,
      on: a.user_id == u.id,
      where: u.email == ^email,
      select: %{
        name: a.name,
        email: u.email,
        partner_requested: a.partner_requested,
        has_partner: a.has_partner,
        requested_by: a.requested_by
      }
  end
end
