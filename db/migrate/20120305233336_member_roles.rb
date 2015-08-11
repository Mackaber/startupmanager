class MemberRoles < ActiveRecord::Migration
  def up
    Member.where(["role_name IN (?)", ["Primary Investor", "Investor", "Advisor", "Other"]]).update_all(:role_name => "Manager")
    Member.where(["role_name IN (?)", ["Founder", "Employee"]]).update_all(:role_name => "Contributor")
  end

  def down
  end
end
