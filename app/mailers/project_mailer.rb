class ProjectMailer < ActionMailer::Base
  
  def goal_invite(member)
    @member = member
    mail(
      :to => member.user.email,
      :subject => "Your Next Step: Invite Team Members"        
    )
  end
  
  def goal_interview(member)
    @member = member
    mail(
      :to => member.user.email,
      :subject => "Your Next Step: Store a Customer Interview"        
    )
  end
  
  def goal_validate(member)
    @member = member
    mail(
      :to => member.user.email,
      :subject => "Your Next Step: Validate a Hypothesis"        
    )
  end
  
  def goal_test(member)
    @member = member
    mail(
      :to => member.user.email,
      :subject => "Your Next Step: Test a Hypothesis"        
    )
  end
  
  def goal_hypothesis(member)
    @member = member
    mail(
      :to => member.user.email,
      :subject => "Your Next Step: Create a Hypothesis"        
    )
  end
  
  def goal_canvas(member)
    @member = member
    mail(
      :to => member.user.email,
      :subject => "Your Next Step: Fill Out the Canvas"        
    )
  end 
  
end
