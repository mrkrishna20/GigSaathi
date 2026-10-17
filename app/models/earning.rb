class Earning < ApplicationRecord
  belongs_to :user

  scope :ordered, -> { order(work_date: :desc, created_at: :desc) }

  before_validation :normalize_blank_expense_fields

  validates :work_date, presence: true
  validates :total_earnings, presence: true,
                             numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 99_999_999.99 }
  validates :fuel_expenses, :food_expenses, :other_expenses,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 99_999_999.99 }

  def total_expenses
    [ fuel_expenses, food_expenses, other_expenses ].sum { |amount| amount.to_d }
  end

  def net_earnings
    total_earnings.to_d - total_expenses
  end

  private

  def normalize_blank_expense_fields
    %i[fuel_expenses food_expenses other_expenses].each do |field|
      raw_value = attributes_before_type_cast[field.to_s]
      self[field] = 0 if raw_value.blank?
    end
  end
end
