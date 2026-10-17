class CreateUsersAndSecureEarnings < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, limit: 254
      t.string :password_digest, null: false

      t.timestamps
    end

    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"

    add_reference :earnings, :user, foreign_key: true, index: false
    add_index :earnings, %i[user_id work_date created_at],
              order: { work_date: :desc, created_at: :desc },
              name: "index_earnings_on_user_and_workday"
    add_check_constraint :earnings, "user_id IS NOT NULL",
                         name: "earnings_must_belong_to_a_user", validate: false
  end
end
