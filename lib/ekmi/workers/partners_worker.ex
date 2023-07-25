defmodule Ekmi.Workers.PartnersWorker do
  use Oban.Worker, queue: :default

  alias Ekmi.Accounts

  @one_hour 1 * 60 * 60

  @impl true
  def perform(%{args: args}, attempt: 1) do
    args
    |> new(schedule_in: @one_hour)
    |> Oban.insert!()

    Accounts.update_balance_by_scheduled_deposit_amount(args.user["id"])
  end

  def perform(%{args: %{"user" => user}}) do
    Accounts.update_balance_by_scheduled_deposit_amount(user["id"])
  end
end
