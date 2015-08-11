class CanvasItemCascade < ActiveRecord::Migration
  def up
    remove_foreign_key "canvas_items", :name => "canvas_items_original_id_fk"
    add_foreign_key "canvas_items", "canvas_items", :column => "original_id", :dependent => :delete
  end

  def down
  end
end
