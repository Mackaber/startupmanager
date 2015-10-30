#encoding: utf-8
class ResourceMailer < ActionMailer::Base
  
  def question(type, name, email, company, url, location, industry, funded, question_p)
    @name = name
    @email = email
    @company = company
    @url = url
    @location = location
    @industry = industry
    @funded = funded
    @question = question_p
    
    case type
    when "banking"
      @subject = "Banking Question from #{@name}"
      @subject << " (#{@company})" unless @company.blank?
      mail(
        :to => "hola@impactum.mx",
        :bcc => ENV["EMAIL_SUPPORT"],
        :subject => "LLL Mail: #{@subject}"
      )
    when "finance"
      @subject = "Finance Question from #{@name}"
      @subject << " (#{@company})" unless @company.blank?
      mail(
        :to => "hola@impactum.mx",
        :bcc => ENV["EMAIL_SUPPORT"],
        :subject => "LLL Mail: #{@subject}"
      )
    when "legal"
      @subject = "Legal Question from #{@name}"
      @subject << " (#{@company})" unless @company.blank?
      mail(
        :to => "hola@impactum.mx",
        :bcc => ENV["EMAIL_SUPPORT"],
        :subject => "LLL Mail: #{@subject}"
      )
    end
  end
  
end
