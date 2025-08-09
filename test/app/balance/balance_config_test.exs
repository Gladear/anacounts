defmodule App.Balance.BalanceConfigTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.Balance.BalanceConfigsFixtures

  alias App.Balance.BalanceConfig

  setup do
    %{user: user_fixture()}
  end

  describe "revenues_changeset/2" do
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
  end
end
