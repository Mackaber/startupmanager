class ChargeOrgOptional < ActiveRecord::Migration
  def up
    change_column_null "charges", "organization_id", true
    remove_foreign_key "charges", :name => "charges_organization_id_fk"
    add_foreign_key "charges", "organizations", :dependent => :nullify    
  end

  def down
  end
end
