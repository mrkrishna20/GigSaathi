class CreateEarnings < ActiveRecord::Migration[8.1]
  def change
    create_table :earnings do |t|
      t.date :work_date, null: false
      t.decimal :total_earnings, precision: 10, scale: 2, null: false
      t.decimal :fuel_expenses, precision: 10, scale: 2, null: false, default: 0
      t.decimal :food_expenses, precision: 10, scale: 2, null: false, default: 0
      t.decimal :other_expenses, precision: 10, scale: 2, null: false, default: 0

      t.timestamps
    end

    add_index :earnings, :work_date
  end
end
