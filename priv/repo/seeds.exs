# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Ekmi.Repo.insert!(%Ekmi.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias Ekmi.Repo
alias Ekmi.Keihi.Category

[
  "Groceries/Food",
  "Transportation",
  "Rent",
  "Utilities",
  "Entertainment",
  "Misc./Hobby"
]
|> Enum.each(fn name ->
  %Category{name: name}
  |> Repo.insert!()
end)
