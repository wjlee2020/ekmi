defmodule Ekmi.Repo do
  use Ecto.Repo,
    otp_app: :ekmi,
    adapter: Ecto.Adapters.Postgres
end
