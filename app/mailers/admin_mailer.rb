class AdminMailer < ActionMailer::Base
  
  default :to => ENV["EMAIL_SYSTEM"]

  def system_error(exception, err, request = nil)
    @err = err
    if exception.is_a?(Exception)
      mail(
        :subject => %Q{#{exception.message} (#{exception.class})#{request ? " at #{request.url} (#{request.env['REQUEST_METHOD']})" : nil}}
      )
    else
      mail(
        :subject => %Q{#{exception}#{request ? " at #{request.url} (#{request.env['REQUEST_METHOD']})" : nil}}
      )      
    end    
  end
  
  def no_cc(organization)
    @organization = organization
    mail(
      :to => ENV["EMAIL_SUPPORT"], 
      :subject => "Missing credit card for billable organization #{organization.to_param}"
    )
  end

end
