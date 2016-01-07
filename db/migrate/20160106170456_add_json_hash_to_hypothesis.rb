class AddJsonHashToHypothesis < ActiveRecord::Migration
  def change
    add_column :hypotheses, :json_hash, :text
  end
end
