class CreateSpreePlan < ActiveRecord::Migration
  def change
    create_table :spree_plans do |t|
      t.string :api_plan_id, nil: false
      t.integer :amount
      t.integer :points
      t.string :interval
      t.integer :interval_count, :default => 1
      t.string :name
      t.string :description
      t.boolean :free_shipping, :default => false
      t.boolean :free_cleaning, :default => false
      t.boolean :special_sales, :default => false
      t.string :currency
      t.integer :recurring_id
      t.integer :trial_period_days, :default => 0
      t.boolean :active, :default => false
      t.datetime :deleted_at
    end

    add_index :spree_plans, [:deleted_at, :recurring_id, :active]
    add_index :spree_plans, [:deleted_at, :active]
    add_index :spree_plans, [:deleted_at, :recurring_id]
    add_index :spree_plans, :deleted_at
  end
end
