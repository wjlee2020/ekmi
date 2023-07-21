defmodule Ekmi.Workers.FinanceWorker do
  use Oban.Worker, queue: :default

  alias Ekmi.Accounts

  @impl true
  def perform(%{args: %{"finance" => finance, "user" => user} = args, attempt: 1}) do
    args
    |> new(schedule_in: 1)
    |> Oban.insert!()

    Accounts.update_balance(user["id"], finance)
  end

  def perform(%{args: %{"finance" => finance, "user" => user}}) do
    Accounts.update_balance(user["id"], finance)
  end
end
