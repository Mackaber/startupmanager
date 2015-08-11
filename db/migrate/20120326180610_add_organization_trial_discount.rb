class AddOrganizationTrialDiscount < ActiveRecord::Migration
  def up
    create_table :promotions, :force => true do |t|
      t.string :name, :null => false
      t.string :code, :null => false
      t.integer :monthly_discount_percent
      t.integer :months
      t.timestamps
    end
    add_index :promotions, :name, :unique => true
    add_index :promotions, :code, :unique => true
    
    Promotion.reset_column_information
    Promotion.create!(
      :name => "15% off monthly",
      :monthly_discount_percent => 15,
      :months => 12
    )
    
    add_column :organizations, :promotion_id, :integer
    add_index :organizations, :promotion_id
    add_foreign_key :organizations, :promotions
    
    add_column :organizations, :promotion_expires_at, :datetime
    add_index :organizations, :promotion_expires_at
  end

  def down
    drop_table :promotions
  end
end