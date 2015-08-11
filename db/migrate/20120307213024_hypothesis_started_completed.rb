class HypothesisStartedCompleted < ActiveRecord::Migration
  def up
    item_status = ItemStatus.cached_find_by_status("started")
    Hypothesis.where(:item_status_id => item_status.id).find_each do |hypothesis|
      a = hypothesis.audits.where(:action => "update").select{|x| x.audited_changes.has_key?("item_status_id")}.last
      hypothesis.completed_at = a ? a.created_at : hypothesis.updated_at
      hypothesis.save!
    end if item_status
  end

  def down
  end
end
