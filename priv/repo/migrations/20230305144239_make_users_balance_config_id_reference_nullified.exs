defmodule App.Repo.Migrations.MakeUsersBalanceConfigIdReferenceNullified do
  use Ecto.Migration

  def change do
    alter table("users") do
      modify :balance_config_id, references("balance_configs", on_delete: :nilify_all),
        from: references("balance_configs", on_delete: :delete_all)
    end
  end
end
