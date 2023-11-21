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
      where: u.email == ^email
  end
end
