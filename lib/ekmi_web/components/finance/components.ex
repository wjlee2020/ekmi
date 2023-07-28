defmodule EkmiWeb.Finance.Components do
  use EkmiWeb, :html

  def finance_form(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@finance_form}
        id="balance_form"
        phx-submit="update_balance"
        phx-change="validate_balance"
      >
        <.input field={@finance_form[:balance]} type="number" label="Your Balance" required />
        <.input
          field={@finance_form[:scheduled_deposit_amount]}
          type="number"
          label="Amount to deposit"
          required
        />
        <.input
          field={@finance_form[:currency]}
          type="select"
          label="Currency"
          required
          options={["USD", "JPY"]}
        />
        <.input field={@finance_form[:user_id]} type="hidden" />

        <:actions>
          <.button phx-disable-with="Changing...">Change Balance</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
