defmodule App.Repo.Migrations.MakeUsersBalanceConfigIdOnDeleteRestrict do
  use Ecto.Migration

  def change do
    alter table("users") do
      modify :balance_config_id, references("balance_configs", on_delete: :restrict),
        from: references("balance_configs", on_delete: :nilify_all)
    end
  end
end
