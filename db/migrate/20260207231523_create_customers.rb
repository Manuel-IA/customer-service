class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :customer_name
      t.string :address
      t.integer :orders_count, default: 0, null: false

      t.timestamps
    end
  end
end
