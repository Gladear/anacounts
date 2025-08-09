defmodule App.Repo.Migrations.CreateUserBalanceConfig do
  use Ecto.Migration

  def change do
    create table(:user_balance_config) do
      add :annual_income, :binary

      add :user_id, references(:users, on_delete: :delete_all), null: false
    end
  end
end
