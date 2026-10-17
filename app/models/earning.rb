class Earning < ApplicationRecord
  validates :work_date, presence: true
  validates :total_earnings, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 99_999_999.99 }
  validates :fuel_expenses, :food_expenses, :other_expenses,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 99_999_999.99 }

  def total_expenses
    fuel_expenses + food_expenses + other_expenses
  end

  def net_earnings
    total_earnings - total_expenses
  end
end
