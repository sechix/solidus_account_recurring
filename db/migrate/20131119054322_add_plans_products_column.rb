class CreateSpreeSubscription < ActiveRecord::Migration
  def change
    remove_column :spree_plans, :points if column_exists?(:spree_plans, :points)

    add_column :spree_plans, :plan1, :integer, default: 0
    add_index :spree_plans,  :plan1
    add_column :spree_plans, :plan2, :integer, default: 0
    add_index :spree_plans,  :plan2
    add_column :spree_plans, :plan3, :integer, default: 0
    add_index :spree_plans,  :plan3
end
