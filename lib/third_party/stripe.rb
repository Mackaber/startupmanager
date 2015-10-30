# encoding: utf-8
class ThirdParty::Stripe
  
  # Process outstanding charges for orgs with stripe ID
  def process_charges
    # group charges by organization, so there's only one stripe transaction to minimize fees
    Organization.where("id IN (SELECT DISTINCT(organization_id) FROM charges WHERE stripe_charge_id IS NULL)").find_each do |organization|
      begin
        if (organization.stripe_customer_id.nil? && !organization.invoice_billing)
          AdminMailer.no_cc(organization).deliver if (Rails.env == "production")
          next
        end
      
        total = 0
        description = []
        charges = []
        organization.charges.outstanding.find_each do |charge|
          total += charge.amount
          description << charge.comments
          charges << charge
        end
      
        # wait to process charges < $3.00 so we combine into a singe stripe transaction
        unless (charges.empty? || total < 3)
          Charge.transaction do
            begin
              if (stripe_charge = Stripe::Charge.create(
                :amount => (total * 100).to_i,
                :currency => "usd",
                :customer => organization.stripe_customer_id,
                :description => description.join("; ")
              ))
                Rails.logger.debug("STRIPE #{stripe_charge.inspect}")
                charges.each {|charge| charge.update_attributes!(:stripe_charge_id => stripe_charge.id)}
              end
            rescue Stripe::CardError => error
              organization.reset_cc!
            end
          end
        end
      rescue Exception => exception
        @exception = exception
        template = File.read("app/views/layouts/system_error.erb")
        result = ERB.new(template, nil, "<>").result(binding)
        Rails.logger.error("ERROR: #{result}")
        AdminMailer.system_error(exception, result).deliver            
      end
    end
        
  end
    
end