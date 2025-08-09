defmodule App.Repo.Migrations.AddMoneyTransfersCreatorId do
  use Ecto.Migration

  def change do
    alter table("money_transfers") do
      add :creator_id, references("book_members", on_delete: :nilify_all)
    end
  end
end
