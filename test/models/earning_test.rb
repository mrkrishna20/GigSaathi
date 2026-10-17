require "test_helper"

class EarningTest < ActiveSupport::TestCase
  test "calculates total expenses and take-home earnings" do
    earning = Earning.new(
      work_date: Date.current,
      total_earnings: 1_250,
      fuel_expenses: 150,
      food_expenses: 75,
      other_expenses: 25
    )

    assert_equal BigDecimal("250"), earning.total_expenses
    assert_equal BigDecimal("1000"), earning.net_earnings
  end

  test "treats blank expense values as zero" do
    earning = Earning.new(
      work_date: Date.current,
      total_earnings: 600,
      fuel_expenses: "",
      food_expenses: nil,
      other_expenses: "  "
    )

    assert earning.valid?
    assert_equal BigDecimal("0"), earning.total_expenses
    assert_equal BigDecimal("600"), earning.net_earnings
  end

  test "rejects negative amounts" do
    earning = Earning.new(
      work_date: Date.current,
      total_earnings: 200,
      fuel_expenses: -1,
      food_expenses: 0,
      other_expenses: 0
    )

    assert_not earning.valid?
    assert_includes earning.errors.attribute_names, :fuel_expenses
  end

  test "rejects amounts above the database precision" do
    earning = Earning.new(work_date: Date.current, total_earnings: 100_000_000)

    assert_not earning.valid?
    assert_includes earning.errors.attribute_names, :total_earnings
  end
end
