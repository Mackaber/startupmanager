# encoding: utf-8
class LllOnlyInterceptor
  
  def self.delivering_email(mail)
    mail.to = mail.to_addrs.select{|x| x =~ /@(leanlaunchlab)\.com$/}
    mail.cc = mail.cc_addrs.select{|x| x =~ /@(leanlaunchlab)\.com$/}
    mail.bcc = mail.bcc_addrs.select{|x| x =~ /@(leanlaunchlab)\.com$/}
    if mail.destinations.empty?
      mail.to = "nobody"
    end
  end

end