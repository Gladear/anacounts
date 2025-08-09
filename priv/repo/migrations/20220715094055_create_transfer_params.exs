defmodule App.Repo.Migrations.CreateTransferParams do
  use Ecto.Migration

  def change do
    # Create related custom types
    execute(
      "CREATE TYPE balance_means_code AS ENUM ('divide_equally')",
      "DROP TYPE balance_means_code"
    )

    execute(
      """
      CREATE TYPE balance_transfer_params AS (
        means_code balance_means_code,
        params JSONB
      )
      """,
      """
      DROP TYPE balance_transfer_params
      """
    )
  end
end
