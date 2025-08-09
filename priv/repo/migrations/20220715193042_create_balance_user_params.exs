defmodule App.Repo.Migrations.CreateBalanceUserParams do
  use Ecto.Migration

  def change do
    create table(:balance_user_params) do
      add(:means_code, :balance_means_code, null: false)
      add(:params, :map, null: false)

      add(:user_id, references(:users, on_delete: :delete_all, on_update: :restrict), null: false)
    end
  end
end
