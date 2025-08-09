defmodule App.Repo.Migrations.DropBalanceConfigUserOrMemberConstraint do
  use Ecto.Migration

  def change do
    drop constraint(:balance_configs, :either_user_or_book_member_id,
           check: "num_nulls(user_id, book_member_id) = 1"
         )
  end
end
