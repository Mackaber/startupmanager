class Jobs::Notify::NewCharge < Jobs::Job
  
  def self.run(charge_id)
    if (charge = Charge.find_by_id(charge_id))
      OrganizationMailer.new_charge(charge).deliver
    end
  end
  
end