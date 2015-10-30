#encoding: utf-8
class CustomDeviseMailer < Devise::Mailer
  
  def headers_for(action)
    #this has been overridden just to provide a different address for reply_to
    #everything else is stock devise
    #this also required moving the views user by the mailer to views/custom_devise_mailer from views/devise/mailer
    headers = {
        :subject => translate(devise_mapping, action),
        :from => mailer_sender(devise_mapping),
        :to => resource.email,
        :template_path => template_paths
    }

    if resource.respond_to?(:headers_for)
      headers.merge!(resource.headers_for(action))
    end

    unless headers.key?(:reply_to)
      headers[:reply_to] = headers[:from]
    end

    headers
  end
end