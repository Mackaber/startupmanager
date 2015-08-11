class AddHypothesisCompletedReason < ActiveRecord::Migration
  def up
    add_column "hypotheses", "completed_reason", :string
  end

  def down
  end
end
