class AddUserSource < ActiveRecord::Migration
  def up
    add_column "users", "source", :string
  end

  def down
  end
end
