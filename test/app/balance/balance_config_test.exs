defmodule App.Balance.BalanceConfigTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.Balance.BalanceConfigsFixtures

  alias App.Balance.BalanceConfig

  setup do
    %{user: user_fixture()}
  end

  describe "revenues_changeset/2" do
    test "returns a changeset" do
      balance_config = balance_config_fixture()

      assert %Ecto.Changeset{} =
               changeset =
               BalanceConfig.revenues_changeset(balance_config, %{
                 revenues: 2345
               })

      assert changeset.valid?
      assert changeset.changes == %{revenues: 2345}
    end

    test "allows valid `:revenues`", %{user: user} do
      changeset =
        BalanceConfig.revenues_changeset(
          %BalanceConfig{owner_id: user.id},
          balance_config_attributes(revenues: 0)
        )

      assert changeset.valid?
    end

    test "does not allow negative `:revenues`", %{user: user} do
      changeset =
        BalanceConfig.revenues_changeset(
          %BalanceConfig{owner_id: user.id},
          balance_config_attributes(revenues: -1)
        )

      refute changeset.valid?
      assert errors_on(changeset) == %{revenues: ["must be greater than or equal to 0"]}
    end

    test "cannot change the owner" do
      balance_config = balance_config_fixture()

      assert %Ecto.Changeset{} =
               changeset =
               BalanceConfig.revenues_changeset(balance_config, %{
                 owner_id: user_fixture().id
               })

      assert changeset.valid?
      assert changeset.changes == %{}
    end
  end
end
