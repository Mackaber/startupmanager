class Jobs::Billing::ProcessStripe < Jobs::Job      
  def self.run
    ThirdParty::Stripe.new.process_charges
  end
end
