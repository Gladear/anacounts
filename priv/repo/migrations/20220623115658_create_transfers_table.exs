defmodule App.Repo.Migrations.CreateTransfersTable do
  use Ecto.Migration

  def change do
    create table(:transfers_money_transfers) do
      add(:label, :string, null: false)
      add(:amount, :money_with_currency, null: false)
      add(:type, :string, null: false)
      add(:date, :utc_datetime, default: fragment("now()"), null: false)

      add(:book_id, references(:accounts_books, on_delete: :delete_all), null: false)
      add(:holder_id, references(:accounts_book_members, on_delete: :restrict), null: false)

      timestamps()
    end

    create table(:transfers_peers) do
      add(:transfer_id, references(:transfers_money_transfers, on_delete: :delete_all),
        null: false
      )

      add(:member_id, references(:accounts_book_members, on_delete: :restrict), null: false)

      add(:weight, :decimal, default: "1.0", null: false)
    end
  end
end
