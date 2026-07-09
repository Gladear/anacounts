defmodule App.Repo.Migrations.CreateUserPasskeys do
  use Ecto.Migration

  def change do
    create table(:user_passkeys) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :credential_id, :binary, null: false
      add :public_key, :binary, null: false
      add :sign_count, :integer, null: false
      add :aaguid, :binary
      add :device_name, :string, null: false

      timestamps()
    end

    create unique_index(:user_passkeys, [:credential_id])
    create index(:user_passkeys, [:user_id])
    create unique_index(:user_passkeys, [:user_id, :device_name])
  end
end
