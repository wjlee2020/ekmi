defmodule Ekmi.Workers.FinanceWorker do
  @moduledoc false

  use Oban.Worker, queue: :default

  alias Ekmi.Accounts

  @one_month 1 * 60 * 60 * 24 * 30

  @impl true
  def perform(%{args: %{"user" => user} = args, attempt: 1}) do
    args
    |> new(schedule_in: @one_month)
    |> Oban.insert!()

    Accounts.update_balance_by_scheduled_deposit_amount(user["id"])
  end

  def perform(%{args: %{"user" => user}}) do
    Accounts.update_balance_by_scheduled_deposit_amount(user["id"])
  end
end
